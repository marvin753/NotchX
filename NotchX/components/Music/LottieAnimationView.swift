//
//  LottieAnimationContainer.swift
//  NotchX
//
//  Created by Richard Kunkli on 2024. 10. 29..
//

import SwiftUI
import Defaults

struct LottieAnimationContainer: View {
    @Default(.selectedVisualizer) var selectedVisualizer
    var body: some View {
        if let selectedVisualizer {
            LottieView(url: selectedVisualizer.url, speed: selectedVisualizer.speed, loopMode: .loop)
        } else if let fallbackURL = URL(string: "https://assets9.lottiefiles.com/packages/lf20_mniampqn.json") {
            LottieView(url: fallbackURL, speed: 1.0, loopMode: .loop)
        } else {
            EmptyView()
        }
    }
}

#Preview {
    LottieAnimationContainer()
}
