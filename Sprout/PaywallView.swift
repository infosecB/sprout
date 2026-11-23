import SwiftUI

/// The Sprout Pro upsell sheet. Locked controls present it.
struct PaywallView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Image(systemName: store.isPro ? "checkmark.seal.fill" : "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Brand.accent)
                            .symbolEffect(.bounce, value: store.isPro)
                        Text("Sprout Pro")
                            .font(Brand.font(34, weight: .heavy))
                        Text("One purchase, yours forever.")
                            .font(Brand.font(17, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(ProFeature.all, id: \.self) { feature in
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: feature.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Brand.onAccent)
                                    .frame(width: 38, height: 38)
                                    .background(Brand.accent, in: Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title).font(Brand.font(17))
                                    Text(feature.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 460, alignment: .leading)
                    .card()

                    if store.isPro {
                        Label("Pro is unlocked. Thanks!", systemImage: "checkmark.seal.fill")
                            .font(Brand.font(18))
                            .foregroundStyle(Brand.accent)
                    } else {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            Group {
                                if store.isPurchasing {
                                    ProgressView().tint(Brand.onAccent)
                                } else if let product = store.product {
                                    Text("Unlock for \(product.displayPrice)")
                                } else {
                                    Text(store.isLoading ? "Loading…" : "Unlock Pro")
                                }
                            }
                            .font(Brand.font(19))
                            .frame(maxWidth: 380, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Brand.accent)
                        .disabled(store.isPurchasing)

                        Button("Restore Purchases") {
                            Task { await store.restore() }
                        }
                        .font(.subheadline.weight(.medium))
                    }

                    AboutLinks()
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Brand.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .alert("Sprout Pro", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onChange(of: store.isPro) {
            if store.isPro {
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    PaywallView().environment(Store())
}
