import SwiftUI

/// The main screen. Replace it with the app's real first screen.
struct HomeView: View {
    @Environment(Store.self) private var store
    @Binding var showPaywall: Bool

    var body: some View {
        GeometryReader { proxy in
            let margin = Brand.margin(for: proxy.size)
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 56, weight: .semibold))
                                .foregroundStyle(Brand.accent)
                            Text("Sprout")
                                .font(Brand.font(36, weight: .heavy))
                            Text("Water, feed and repot every houseplant on time, with a care log for each one.")
                                .font(Brand.font(17, weight: .medium))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .card(padding: 28)

                        // An example of a Pro feature gated at the point of use.
                        Button {
                            if !store.isPro { showPaywall = true }
                        } label: {
                            HStack {
                                Label("A Pro feature", systemImage: store.isPro ? "star.fill" : "lock.fill")
                                    .font(Brand.font(17))
                                Spacer()
                                if !store.isPro {
                                    Text("PRO")
                                        .font(Brand.font(12, weight: .heavy))
                                        .foregroundStyle(Brand.onAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Brand.accent, in: Capsule())
                                }
                            }
                            .foregroundStyle(.primary)
                            .card()
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: 640)
                    .padding(margin)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(Brand.background)
                .navigationTitle("Home")
                .toolbarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    HomeView(showPaywall: .constant(false)).environment(Store())
}
