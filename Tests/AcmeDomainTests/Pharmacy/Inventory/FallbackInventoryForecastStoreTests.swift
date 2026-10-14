@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryFallbackInventoryForecastStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.FallbackInventoryForecastStore = Pharmacy.newMemoryFallbackInventoryForecastStore()
        let item = Pharmacy.newFallbackInventoryForecast("code-656", name: "name-635")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
