@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryMetricStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryMetricStore = Pharmacy.newMemoryInventoryMetricStore()
        let item = Pharmacy.newInventoryMetric("code-594", title: "title-552")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
