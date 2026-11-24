import SwiftUI

/// The Sprout Pro upsell sheet. Locked controls present it.
struct PaywallView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: store.isPro ? "checkmark.seal" : "camera.macro")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(store.isPro ? Brand.accent : Brand.leaf)
                            .symbolEffect(.bounce, value: store.isPro)
                            .padding(.bottom, 4)
                        Text("Sprout Pro")
                            .font(Brand.font(34, weight: .medium))
                        Text("One purchase, yours forever.")
                            .font(Brand.font(18, weight: .regular))
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(ProFeature.all, id: \.self) { feature in
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Image(systemName: feature.icon)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(Brand.accent)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title).font(.body.weight(.semibold))
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
                            .font(.body.weight(.semibold))
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
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: 380, minHeight: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: Brand.radius))
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
