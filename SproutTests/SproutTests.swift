import Foundation
import Testing
@testable import Sprout

struct WidgetSnapshotTests {
    private func scratchDefaults() -> UserDefaults {
        let name = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func roundTrips() {
        let defaults = scratchDefaults()
        let snapshot = WidgetSnapshot(isPro: true, headline: "Hello", detail: "World", updated: .now)
        #expect(snapshot.save(to: defaults))
        let loaded = WidgetSnapshot.load(from: defaults)
        #expect(loaded.headline == "Hello")
        #expect(loaded.isPro)
    }

    @Test func skipsSavingWhenOnlyTheDateChanged() {
        let defaults = scratchDefaults()
        WidgetSnapshot(headline: "Same", updated: .distantPast).save(to: defaults)
        #expect(!WidgetSnapshot(headline: "Same", updated: .now).save(to: defaults))
        #expect(WidgetSnapshot(headline: "Different", updated: .now).save(to: defaults))
    }

    @Test func linksRoundTrip() {
        for tab in AppTab.allCases {
            #expect(AppLink.tab(for: AppLink.url(tab)) == tab)
        }
    }
}

struct ProTests {
    private struct StoreKitFile: Decodable {
        struct Product: Decodable {
            let productID: String
            let type: String
        }
        let products: [Product]
    }

    /// Sprout.storekit sells the product Store asks for, so Pro can be bought from Xcode.
    @Test func storeKitFileSellsTheProProduct() throws {
        let bundle = Bundle(for: BundleToken.self)
        let url = try #require(bundle.url(forResource: "Sprout", withExtension: "storekit"))
        let file = try JSONDecoder().decode(StoreKitFile.self, from: Data(contentsOf: url))
        let product = try #require(file.products.first { $0.productID == Store.proID })
        #expect(product.type == "NonConsumable")
    }
}

private final class BundleToken {}
