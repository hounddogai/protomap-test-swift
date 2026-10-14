@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryBatchStore = Pharmacy.newMemoryInventoryBatchStore()
        let item = Pharmacy.newInventoryBatch("code-657", title: "title-266")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
