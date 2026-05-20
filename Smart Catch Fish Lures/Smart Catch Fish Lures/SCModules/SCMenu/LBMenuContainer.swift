//
//  LBMenuContainer.swift
//  Smart Catch Fish Lures
//
//


import SwiftUI

struct SCMenuContainer: View {
    @AppStorage("firstOpenSC") var firstOpen: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if firstOpen {
                    SCOnboardingView(getStartBtnTapped: {
                        firstOpen = false
                    })
                } else {
                    SCMenuView()
                }
            }
        }
    }
}

struct SCMenuView: View {
    @State var selectedTab = 0
    @StateObject var viewModel = SmartCatchViewModel()
    private let tabs = ["Catch\nLog", "My\nBox", "Advisor", "Analytics", "Profile"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            TabView(selection: $selectedTab) {
                CatchLogView(viewModel: viewModel)
                    .tag(0)
                
                TackleBoxView(viewModel: viewModel)
                    .tag(1)
                
                SmartAdvisorView(viewModel: viewModel)
                    .tag(2)
                
                AnalyticsView(viewModel: viewModel)
                    .tag(3)
                
                ProfileView(viewModel: viewModel)
                    .tag(4)
                
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            customTabBar
        }
        .background(
            Image(.appBgSC)
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
                            .frame(height: selectedTab == index ? 40 : 24)
                        
                        Text(tabs[index])
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedTab == index ? .tabAccent : .white.opacity(0.5))
                        
                    }
                    .frame(height: 75)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(12)
        .padding(.bottom)
        .frame(maxWidth: .infinity)
        .background(.tabBarBg.opacity(0.9))
    }
    
    private func icon(for index: Int) -> String {
        switch index {
        case 0: return "tab1IconSC"
        case 1: return "tab2IconSC"
        case 2: return "tab3IconSC"
        case 3: return "tab4IconSC"
        case 4: return "tab5IconSC"
            
        default: return ""
        }
    }
    
    private func selectedIcon(for index: Int) -> String {
        switch index {
        case 0: return "tab1IconSelectedFP"
        case 1: return "tab2IconSelectedFP"
        case 2: return "tab3IconSelectedFP"
        case 3: return "tab4IconSelectedFP"
        case 4: return "tab5IconSelectedFP"
        default: return ""
        }
    }
}

#Preview {
    SCMenuContainer()
}
