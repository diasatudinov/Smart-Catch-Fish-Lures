import SwiftUI

struct LBMenuContainer: View {
    @AppStorage("firstOpenBB") var firstOpen: Bool = true
    
    var body: some View {
        NavigationStack {
            FPMenuView()
        }
    }
}

struct FPMenuView: View {
    @State var selectedTab = 1
    @StateObject var viewModel = FoodPyramidViewModel()
    private let tabs = ["Calc", "Tracker", "Stats"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            TabView(selection: $selectedTab) {
                StatisticsView(viewModel: viewModel)
                    .tag(0)
                
                MainPyramidView(viewModel: viewModel)
                    .tag(1)
                
                FPStorageRoomView(viewModel: viewModel)
                    .tag(2)
                
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            customTabBar
        }
        .background(
            Image(.appBgFP)
                .resizable()
        )
        .ignoresSafeArea(edges: .vertical)
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    selectedTab = index
                } label: {
                    VStack(spacing: 3) {
                        Image(selectedTab == index ? selectedIcon(for: index) : icon(for: index))
                            .resizable()
                            .scaledToFit()
                            .frame(height: selectedTab == index ? 50 : 32)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.tabBarBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.bottom, 20)
        .padding(.horizontal, 26)
    }
    
    private func icon(for index: Int) -> String {
        switch index {
        case 0: return "tab1IconFP"
        case 1: return "tab2IconFP"
        case 2: return "tab3IconFP"
        default: return ""
        }
    }
    
    private func selectedIcon(for index: Int) -> String {
        switch index {
        case 0: return "tab1IconSelectedFP"
        case 1: return "tab2IconSelectedFP"
        case 2: return "tab3IconSelectedFP"
        default: return ""
        }
    }
}

#Preview {
    LBMenuContainer()
}
