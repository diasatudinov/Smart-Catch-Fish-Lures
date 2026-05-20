//
//  FAOnboardingView.swift
//  Smart Catch Fish Lures
//
//  Created by Dias Atudinov on 20.05.2026.
//


import SwiftUI

struct FAOnboardingView: View {
    var getStartBtnTapped: () -> ()
        @State var count = 0
        
        var onbIcon: Image {
            switch count {
            case 0:
                Image(.onboardingIcon1FA)
            case 1:
                Image(.onboardingIcon2FA)
            case 2:
                Image(.onboardingIcon3FA)
            case 3:
                Image(.onboardingIcon4FA)
            default:
                Image(.onboardingIcon1FA)
            }
        }
        
        var onbTitle: String {
            switch count {
            case 0:
                "Your Aquarium. Under\nControl."
            case 1:
                "Track What Matters"
            case 2:
                "Never Miss a Task"
            case 3:
                "Start Your Aquarium Journey"
            default:
                "Spin Your Meals"
            }
        }
        
        var onbDescription: String {
            switch count {
            case 0:
                "Track your fish, water, and care routines in\none place"
            case 1:
                "Monitor water parameters and fish health\nwith ease"
            case 2:
                "Get smart reminders for feeding, cleaning,\nand care"
            case 3:
                "Add your first fish and build your perfect\necosystem"
            default:
                ""
            }
        }
        
        var body: some View {
            VStack {
                
                HStack {
                                        
                    if count == 0 {
                        Button {
                            getStartBtnTapped()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding(.trailing, 40)
                
                Spacer()
                
                onbIcon
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, count % 2 == 0 ? 52 : 36)
                
                VStack(spacing: 16) {
                    Text(onbTitle)
                        .font(.system(size: 24, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    
                    Text(onbDescription)
                        .font(.system(size: 16, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                    
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                
                Spacer()
                
                VStack {
                    
                    HStack {
                        if count == 0 {
                            Circle()
                                .fill(.yellow)
                                .frame(width: 10, height: 10)
                                
                        } else {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 10, height: 10)
                        }
                        
                        
                        if count == 1 {
                            Circle()
                                .fill(.yellow)
                                .frame(width: 10, height: 10)

                        } else {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 10, height: 10)
                        }
                        
                        if count == 2 {
                            Circle()
                                .fill(.yellow)
                                .frame(width: 10, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 10, height: 10)
                        }
                        
                        if count == 3 {
                            Circle()
                                .fill(.yellow)
                                .frame(width: 10, height: 10)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        } else {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    VStack(spacing: 16) {
                        
                        Button {
                            if count < 3 {
                                count += 1
                                
                            } else {
                                getStartBtnTapped()
                            }
                        } label: {
                            Image(count < 3 ? .nextBtnFA : .getStartedBtnFA)
                                .resizable()
                                .scaledToFit()
                                .padding(.horizontal, 24)
                        }
                        
                        if count == 3 {
                            Button {
                                getStartBtnTapped()
                            } label: {
                                Text("Skip")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(
                Image(.onboardingBgFA)
                    .resizable()
                    .ignoresSafeArea()
            )
        }
        
        
        private func additionalInfoCell<Content: View>(
            text: String,
            @ViewBuilder content: () -> Content
        ) -> some View {
            HStack(alignment: .center, spacing: 8) {
                content()
                
                Text(text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        
    }

#Preview {
    FAOnboardingView(getStartBtnTapped: {})
}