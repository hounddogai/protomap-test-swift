@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryAdjustmentStore = Pharmacy.newMemoryInventoryAdjustmentStore()
        let item = Pharmacy.newInventoryAdjustment("code-74", label: "label-612")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
