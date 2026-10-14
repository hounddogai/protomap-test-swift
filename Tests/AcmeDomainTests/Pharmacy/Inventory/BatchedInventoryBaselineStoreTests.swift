@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryBatchedInventoryBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.BatchedInventoryBaselineStore = Pharmacy.newMemoryBatchedInventoryBaselineStore()
        let item = Pharmacy.newBatchedInventoryBaseline("code-445", label: "label-89")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
