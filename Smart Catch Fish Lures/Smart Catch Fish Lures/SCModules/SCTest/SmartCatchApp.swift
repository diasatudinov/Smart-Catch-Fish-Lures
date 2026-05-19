import SwiftUI
import PhotosUI
import UIKit

// MARK: - App

@main
struct SmartCatchApp: App {
    var body: some Scene {
        WindowGroup {
            SmartCatchRootView()
        }
    }
}

// MARK: - Models

enum WeatherCondition: String, CaseIterable, Identifiable, Codable {
    case sunny = "Sunny"
    case cloudy = "Cloudy"
    case rain = "Rain"
    case foggy = "Foggy"
    case windy = "Windy"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sunny: return "sun.max"
        case .cloudy: return "cloud"
        case .rain: return "cloud.rain"
        case .foggy: return "cloud.fog"
        case .windy: return "wind"
        }
    }
}

enum LureCategory: String, CaseIterable, Identifiable, Codable {
    case wobblers = "Wobblers"
    case spoons = "Spoons"
    case silicone = "Silicone"
    case liveBait = "Live Bait"
    case plantBait = "Plant Bait"

    var id: String { rawValue }
}

struct Lure: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var color: String
    var category: LureCategory
    var weightGrams: Double
    var imageData: Data?
}

struct CatchRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var fishName: String
    var weightKg: Double
    var lengthCm: Double
    var weather: WeatherCondition
    var temperatureC: Int
    var lureID: UUID
    var lureNameSnapshot: String
    var date: Date = Date()
    var imageData: Data?
}

struct LureRecommendation: Identifiable {
    var id: UUID { lure.id }
    let lure: Lure
    let score: Int
    let confidence: Int
    let reason: String
}

struct SmartCatchData: Codable {
    var catches: [CatchRecord]
    var lures: [Lure]
}

// MARK: - ViewModel / Store

final class SmartCatchViewModel: ObservableObject {

    @Published var catches: [CatchRecord] = [] {
        didSet { save() }
    }

    @Published var lures: [Lure] = [] {
        didSet { save() }
    }

    @Published var isOfflineMode: Bool = true

    let fishBase: [String] = [
        "Pike", "Perch", "Zander", "Catfish", "Asp",
        "Trout", "Chub", "Carp", "Crucian Carp", "Bream",
        "Roach", "Tench", "Rudd", "Common Carp", "Grayling"
    ]

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("smart_catch_data.json")
    }

    init() {
        load()

        if lures.isEmpty {
            lures = [
                Lure(name: "Acid Vibrotail", color: "Chartreuse", category: .silicone, weightGrams: 18),
                Lure(name: "Silver Spoon", color: "Silver", category: .spoons, weightGrams: 12),
                Lure(name: "Rainbow Wobbler", color: "Rainbow", category: .wobblers, weightGrams: 15),
                Lure(name: "Black Silicone", color: "Black", category: .silicone, weightGrams: 10)
            ]
        }
    }

    // MARK: Add

    func addLure(
        name: String,
        color: String,
        category: LureCategory,
        weightGrams: Double,
        imageData: Data?
    ) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanColor = color.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else { return }

        let lure = Lure(
            name: cleanName,
            color: cleanColor.isEmpty ? "Unknown" : cleanColor,
            category: category,
            weightGrams: weightGrams,
            imageData: imageData
        )

        lures.append(lure)
    }

    func addCatch(
        fishName: String,
        weightKg: Double,
        lengthCm: Double,
        weather: WeatherCondition,
        temperatureC: Int,
        lure: Lure,
        imageData: Data?
    ) {
        let cleanFish = fishName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanFish.isEmpty else { return }

        let record = CatchRecord(
            fishName: cleanFish,
            weightKg: weightKg,
            lengthCm: lengthCm,
            weather: weather,
            temperatureC: temperatureC,
            lureID: lure.id,
            lureNameSnapshot: lure.name,
            imageData: imageData
        )

        catches.insert(record, at: 0)
    }

    // MARK: Stats

    var totalCatches: Int {
        catches.count
    }

    var totalWeight: Double {
        catches.reduce(0) { $0 + $1.weightKg }
    }

    var biggestCatch: CatchRecord? {
        catches.max { $0.weightKg < $1.weightKg }
    }

    var favoriteFish: String {
        let groups = Dictionary(grouping: catches, by: { $0.fishName })
        return groups.max { $0.value.count < $1.value.count }?.key ?? "No data"
    }

    var mostSuccessfulLure: Lure? {
        lures.max { successCount(for: $0.id) < successCount(for: $1.id) }
    }

    var mostProductiveMonth: String {
        let grouped = Dictionary(grouping: catches) { catchRecord in
            Calendar.current.component(.month, from: catchRecord.date)
        }

        guard let month = grouped.max(by: { $0.value.count < $1.value.count })?.key else {
            return "No data"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.monthSymbols[month - 1]
    }

    var bestWeather: WeatherCondition? {
        let grouped = Dictionary(grouping: catches, by: { $0.weather })
        return grouped.max { $0.value.count < $1.value.count }?.key
    }

    func successCount(for lureID: UUID) -> Int {
        catches.filter { $0.lureID == lureID }.count
    }

    func monthlyWeights() -> [(month: String, weight: Double)] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM"

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: catches) { record in
            calendar.component(.month, from: record.date)
        }

        return (1...12).map { month in
            let date = calendar.date(from: DateComponents(year: 2026, month: month, day: 1)) ?? Date()
            let name = formatter.string(from: date)
            let weight = grouped[month]?.reduce(0) { $0 + $1.weightKg } ?? 0
            return (name, weight)
        }
    }

    func topLures() -> [(lure: Lure, count: Int)] {
        lures
            .map { ($0, successCount(for: $0.id)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    // MARK: Smart Advisor

    func recommendations(
        targetFish: String,
        weather: WeatherCondition
    ) -> [LureRecommendation] {
        guard !lures.isEmpty, !catches.isEmpty else {
            return []
        }

        let scored: [LureRecommendation] = lures.compactMap { lure in
            let history = catches.filter { $0.lureID == lure.id }

            guard !history.isEmpty else {
                return nil
            }

            let sameFishSameWeather = history.filter {
                $0.fishName.lowercased() == targetFish.lowercased()
                && $0.weather == weather
            }.count

            let sameFishAnyWeather = history.filter {
                $0.fishName.lowercased() == targetFish.lowercased()
            }.count

            let sameWeatherAnyFish = history.filter {
                $0.weather == weather
            }.count

            let totalSuccess = history.count

            let score =
            sameFishSameWeather * 100 +
            sameFishAnyWeather * 45 +
            sameWeatherAnyFish * 20 +
            totalSuccess * 10

            guard score > 0 else {
                return nil
            }

            let confidence = min(99, max(45, score / 2))

            let reason: String
            if sameFishSameWeather > 0 {
                reason = "Worked for \(targetFish) in \(weather.rawValue.lowercased()) weather"
            } else if sameFishAnyWeather > 0 {
                reason = "Worked for \(targetFish) before"
            } else if sameWeatherAnyFish > 0 {
                reason = "Worked in similar weather"
            } else {
                reason = "General successful lure"
            }

            return LureRecommendation(
                lure: lure,
                score: score,
                confidence: confidence,
                reason: reason
            )
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0 }
    }

    // MARK: Persistence

    private func save() {
        let dataModel = SmartCatchData(catches: catches, lures: lures)

        do {
            let data = try JSONEncoder().encode(dataModel)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Save error:", error)
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(SmartCatchData.self, from: data)
            catches = decoded.catches
            lures = decoded.lures
        } catch {
            print("Load error:", error)
        }
    }
}

// MARK: - Root

struct SmartCatchRootView: View {
    @StateObject private var viewModel = SmartCatchViewModel()

    var body: some View {
        TabView {
            CatchLogView(viewModel: viewModel)
                .tabItem {
                    Label("Catch Log", systemImage: "house")
                }

            TackleBoxView(viewModel: viewModel)
                .tabItem {
                    Label("My Box", systemImage: "shippingbox")
                }

            SmartAdvisorView(viewModel: viewModel)
                .tabItem {
                    Label("Advisor", systemImage: "sparkles")
                }

            AnalyticsView(viewModel: viewModel)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }

            ProfileView(viewModel: viewModel)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(.cyan)
    }
}

// MARK: - Catch Log

struct CatchLogView: View {
    @ObservedObject var viewModel: SmartCatchViewModel
    @State private var showNewCatch = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            StatCard(title: "Fish Caught", value: "\(viewModel.totalCatches)")
                            StatCard(title: "kg Total", value: oneDigit(viewModel.totalWeight))
                        }

                        Text("Recent Catches")
                            .font(.headline)

                        if viewModel.catches.isEmpty {
                            EmptyStateView(
                                title: "No catches yet",
                                subtitle: "Tap + Got it! to save your first trophy."
                            )
                        } else {
                            ForEach(viewModel.catches) { catchRecord in
                                NavigationLink {
                                    CatchDetailsView(catchRecord: catchRecord, viewModel: viewModel)
                                } label: {
                                    CatchCard(catchRecord: catchRecord)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }

                VStack {
                    Spacer()

                    Button {
                        showNewCatch = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("Got it!")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .padding()
                }
            }
            .navigationTitle("Catch Log")
            .sheet(isPresented: $showNewCatch) {
                NewCatchView(viewModel: viewModel)
            }
        }
    }
}

struct CatchCard: View {
    let catchRecord: CatchRecord

    var body: some View {
        HStack(spacing: 12) {
            AppImageView(data: catchRecord.imageData, placeholder: "fish", size: 58)

            VStack(alignment: .leading, spacing: 6) {
                Text(catchRecord.fishName)
                    .font(.headline)

                Text("\(oneDigit(catchRecord.weightKg)) kg • \(Int(catchRecord.lengthCm)) cm")
                    .foregroundColor(.secondary)

                Text(catchRecord.lureNameSnapshot)
                    .font(.caption)
                    .foregroundColor(.cyan)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: catchRecord.weather.icon)
                Text(shortDate(catchRecord.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct CatchDetailsView: View {
    let catchRecord: CatchRecord
    @ObservedObject var viewModel: SmartCatchViewModel

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 18) {
                    AppImageView(data: catchRecord.imageData, placeholder: "fish", size: 180)

                    Text(catchRecord.fishName)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(longDate(catchRecord.date))
                        .foregroundColor(.secondary)

                    HStack {
                        StatCard(title: "kg", value: oneDigit(catchRecord.weightKg))
                        StatCard(title: "cm", value: "\(Int(catchRecord.lengthCm))")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Conditions")
                            .font(.headline)

                        InfoRow(
                            icon: catchRecord.weather.icon,
                            title: catchRecord.weather.rawValue,
                            subtitle: "Weather"
                        )

                        InfoRow(
                            icon: "thermometer",
                            title: "\(catchRecord.temperatureC)°C",
                            subtitle: "Temperature"
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Successful Lure")
                            .font(.headline)

                        InfoRow(
                            icon: "scope",
                            title: catchRecord.lureNameSnapshot,
                            subtitle: "Used lure"
                        )
                    }
                    .padding()
                    .background(Color.cyan.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
        }
        .navigationTitle("Catch Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - New Catch

struct NewCatchView: View {
    @ObservedObject var viewModel: SmartCatchViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fishName = "Pike"
    @State private var customFishName = ""
    @State private var useCustomFish = false

    @State private var weightKg = 2.5
    @State private var lengthCm = 45.0
    @State private var weather: WeatherCondition = .cloudy
    @State private var temperatureC = 15.0
    @State private var selectedLureID: UUID?
    @State private var imageData: Data?

    var selectedLure: Lure? {
        viewModel.lures.first { $0.id == selectedLureID }
    }

    var finalFishName: String {
        useCustomFish ? customFishName : fishName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PhotoPickerView(imageData: $imageData)

                        SectionTitle("Fish Type")

                        Picker("Fish", selection: $fishName) {
                            ForEach(viewModel.fishBase, id: \.self) { fish in
                                Text(fish).tag(fish)
                            }
                        }
                        .pickerStyle(.menu)

                        Toggle("Custom fish name", isOn: $useCustomFish)

                        if useCustomFish {
                            TextField("Type fish name", text: $customFishName)
                                .textFieldStyle(.roundedBorder)
                        }

                        SectionTitle("Weight: \(oneDigit(weightKg)) kg")
                        Slider(value: $weightKg, in: 0.1...30, step: 0.1)

                        SectionTitle("Length: \(Int(lengthCm)) cm")
                        Slider(value: $lengthCm, in: 5...250, step: 1)

                        SectionTitle("Weather")

                        ChipGrid(
                            items: WeatherCondition.allCases.map { $0.rawValue },
                            selected: weather.rawValue
                        ) { value in
                            weather = WeatherCondition(rawValue: value) ?? .cloudy
                        }

                        SectionTitle("Temperature: \(Int(temperatureC))°C")
                        Slider(value: $temperatureC, in: -20...45, step: 1)

                        SectionTitle("Used Lure")

                        if viewModel.lures.isEmpty {
                            EmptyStateView(
                                title: "No lures",
                                subtitle: "Add lure in My Box first."
                            )
                        } else {
                            ForEach(viewModel.lures) { lure in
                                Button {
                                    selectedLureID = lure.id
                                } label: {
                                    HStack {
                                        AppImageView(data: lure.imageData, placeholder: "scope", size: 46)

                                        VStack(alignment: .leading) {
                                            Text(lure.name)
                                                .font(.headline)
                                            Text("\(lure.category.rawValue) • \(oneDigit(lure.weightGrams))g")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if selectedLureID == lure.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(selectedLureID == lure.id ? 0.16 : 0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            guard let lure = selectedLure else { return }

                            viewModel.addCatch(
                                fishName: finalFishName,
                                weightKg: weightKg,
                                lengthCm: lengthCm,
                                weather: weather,
                                temperatureC: Int(temperatureC),
                                lure: lure,
                                imageData: imageData
                            )

                            dismiss()
                        } label: {
                            Text("Save Trophy")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedLure == nil ? Color.gray : Color.cyan)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .disabled(selectedLure == nil || finalFishName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Catch")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Tackle Box

struct TackleBoxView: View {
    @ObservedObject var viewModel: SmartCatchViewModel
    @State private var selectedCategory: LureCategory?
    @State private var showAddLure = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var filteredLures: [Lure] {
        guard let selectedCategory else {
            return viewModel.lures
        }

        return viewModel.lures.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                CategoryChip(
                                    title: "All",
                                    isSelected: selectedCategory == nil
                                ) {
                                    selectedCategory = nil
                                }

                                ForEach(LureCategory.allCases) { category in
                                    CategoryChip(
                                        title: category.rawValue,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredLures) { lure in
                                LureCard(
                                    lure: lure,
                                    successCount: viewModel.successCount(for: lure.id)
                                )
                            }

                            Button {
                                showAddLure = true
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                    Text("Add Lure")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                        .foregroundColor(.cyan.opacity(0.6))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Tackle Box")
            .sheet(isPresented: $showAddLure) {
                AddLureView(viewModel: viewModel)
            }
        }
    }
}

struct LureCard: View {
    let lure: Lure
    let successCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppImageView(data: lure.imageData, placeholder: "scope", size: 70)

            Text(lure.name)
                .font(.headline)
                .lineLimit(1)

            Text(lure.color)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("\(oneDigit(lure.weightGrams))g")
                Spacer()
                Text("\(successCount) caught")
            }
            .font(.caption)
            .foregroundColor(.cyan)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct AddLureView: View {
    @ObservedObject var viewModel: SmartCatchViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var color = ""
    @State private var category: LureCategory = .wobblers
    @State private var weightGrams = 12.0
    @State private var imageData: Data?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PhotoPickerView(imageData: $imageData)

                        SectionTitle("Tackle")
                        Picker("Category", selection: $category) {
                            ForEach(LureCategory.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)

                        SectionTitle("Name and Color")
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)

                        TextField("Color", text: $color)
                            .textFieldStyle(.roundedBorder)

                        SectionTitle("Weight: \(oneDigit(weightGrams))g")
                        Slider(value: $weightGrams, in: 1...80, step: 1)

                        Button {
                            viewModel.addLure(
                                name: name,
                                color: color,
                                category: category,
                                weightGrams: weightGrams,
                                imageData: imageData
                            )

                            dismiss()
                        } label: {
                            Text("Save Lure")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.cyan)
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Lure")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Advisor

struct SmartAdvisorView: View {
    @ObservedObject var viewModel: SmartCatchViewModel

    @State private var targetFish = "Pike"
    @State private var weather: WeatherCondition = .cloudy
    @State private var recommendations: [LureRecommendation] = []
    @State private var didSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Smart Advisor")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("AI-powered lure recommendations")
                                .foregroundColor(.secondary)
                        }

                        SectionTitle("Target Fish")

                        ChipGrid(
                            items: viewModel.fishBase,
                            selected: targetFish
                        ) { value in
                            targetFish = value
                        }

                        SectionTitle("Current Weather")

                        ChipGrid(
                            items: WeatherCondition.allCases.map { $0.rawValue },
                            selected: weather.rawValue
                        ) { value in
                            weather = WeatherCondition(rawValue: value) ?? .cloudy
                        }

                        Button {
                            recommendations = viewModel.recommendations(
                                targetFish: targetFish,
                                weather: weather
                            )
                            didSearch = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Find Best Lure")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        SectionTitle("Top Recommendations")

                        if !didSearch {
                            EmptyStateView(
                                title: "Choose conditions",
                                subtitle: "Select fish and weather, then tap Find Best Lure."
                            )
                        } else if recommendations.isEmpty {
                            EmptyStateView(
                                title: "Not enough information",
                                subtitle: "Add more catches with selected fish, weather and lures."
                            )
                        } else {
                            ForEach(recommendations) { recommendation in
                                RecommendationCard(recommendation: recommendation)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Smart Advisor")
        }
    }
}

struct RecommendationCard: View {
    let recommendation: LureRecommendation

    var body: some View {
        HStack(spacing: 12) {
            AppImageView(data: recommendation.lure.imageData, placeholder: "scope", size: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(recommendation.lure.name)
                    .font(.headline)

                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(recommendation.lure.category.rawValue)
                    .font(.caption2)
                    .foregroundColor(.cyan)
            }

            Spacer()

            Text("\(recommendation.confidence)%")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.cyan)
                .foregroundColor(.black)
                .clipShape(Capsule())
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Analytics

struct AnalyticsView: View {
    @ObservedObject var viewModel: SmartCatchViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Fishing Analytics")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            StatCard(title: "Biggest Pike", value: biggestText)
                            StatCard(title: "Best Day", value: "\(viewModel.totalCatches)")
                        }

                        HStack {
                            StatCard(title: "Most Productive", value: viewModel.mostProductiveMonth)
                            StatCard(title: "Best Weather", value: viewModel.bestWeather?.rawValue ?? "No data")
                        }

                        SectionTitle("Catch Weight by Month")
                        SimpleBarChart(data: viewModel.monthlyWeights())

                        SectionTitle("Most Successful Lures")

                        let topLures = viewModel.topLures()

                        if topLures.isEmpty {
                            EmptyStateView(
                                title: "No lure statistics",
                                subtitle: "Statistics will appear after saving catches."
                            )
                        } else {
                            ForEach(topLures, id: \.lure.id) { item in
                                HStack {
                                    AppImageView(data: item.lure.imageData, placeholder: "scope", size: 46)

                                    VStack(alignment: .leading) {
                                        Text(item.lure.name)
                                            .font(.headline)
                                        Text(item.lure.category.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(item.count) catches")
                                        .foregroundColor(.cyan)
                                }
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
        }
    }

    private var biggestText: String {
        guard let biggest = viewModel.biggestCatch else {
            return "No data"
        }

        return "\(oneDigit(biggest.weightKg)) kg"
    }
}

struct SimpleBarChart: View {
    let data: [(month: String, weight: Double)]

    private var maxWeight: Double {
        max(data.map(\.weight).max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.month) { item in
                VStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.cyan)
                        .frame(height: CGFloat(item.weight / maxWeight) * 140)

                    Text(item.month)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 180)
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Profile

struct ProfileView: View {
    @ObservedObject var viewModel: SmartCatchViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 90))
                                .foregroundColor(.cyan)

                            Text("Angler Pro")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Master Fisher")
                                .font(.caption)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.yellow.opacity(0.2))
                                .foregroundColor(.yellow)
                                .clipShape(Capsule())

                            ProgressView(value: min(Double(viewModel.totalCatches) / 20.0, 1))
                                .tint(.cyan)

                            Text("Level \(max(1, viewModel.totalCatches / 5 + 1))")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 22))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ProfileStatCard(icon: "fish", value: "\(viewModel.totalCatches)", title: "Total Catches")
                            ProfileStatCard(icon: "scope", value: "\(viewModel.lures.count)", title: "Lures Owned")
                            ProfileStatCard(icon: "trophy", value: "\(min(viewModel.totalCatches, 12))", title: "Day Streak")
                            ProfileStatCard(icon: "fish", value: viewModel.favoriteFish, title: "Favorite Fish")
                        }

                        if let lure = viewModel.mostSuccessfulLure {
                            HStack {
                                AppImageView(data: lure.imageData, placeholder: "scope", size: 58)

                                VStack(alignment: .leading) {
                                    Text("Most Successful Lure")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(lure.name)
                                        .font(.headline)

                                    Text("\(viewModel.successCount(for: lure.id)) catches")
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.cyan.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        Toggle("Offline Mode", isOn: $viewModel.isOfflineMode)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text("Smart Catch v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileStatCard: View {
    let icon: String
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Photo Picker

struct PhotoPickerView: View {
    @Binding var imageData: Data?
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            VStack(spacing: 10) {
                AppImageView(data: imageData, placeholder: "camera", size: 120)

                Text("Tap to add photo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else {
                    return
                }

                await MainActor.run {
                    imageData = data
                }
            }
        }
    }
}

// MARK: - Reusable UI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.07, blue: 0.11),
                Color(red: 0.02, green: 0.25, blue: 0.27)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cyan)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 28)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct AppImageView: View {
    let data: Data?
    let placeholder: String
    let size: CGFloat

    var body: some View {
        Group {
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: placeholder)
                    .font(.system(size: size * 0.35))
                    .foregroundColor(.cyan)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.cyan.opacity(0.12))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? Color.cyan : Color.white.opacity(0.12))
                .foregroundColor(isSelected ? .black : .white)
                .clipShape(Capsule())
        }
    }
}

struct ChipGrid: View {
    let items: [String]
    let selected: String
    let onSelect: (String) -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    onSelect(item)
                } label: {
                    Text(item)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected == item ? Color.cyan : Color.white.opacity(0.12))
                        .foregroundColor(selected == item ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - Formatters

func oneDigit(_ value: Double) -> String {
    String(format: "%.1f", value)
}

func shortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}

func longDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "EEEE, MMM d, yyyy"
    return formatter.string(from: date)
}