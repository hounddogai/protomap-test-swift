@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryThresholdStore = Pharmacy.newMemoryInventoryThresholdStore()
        let item = Pharmacy.newInventoryThreshold("code-360", title: "title-235")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
