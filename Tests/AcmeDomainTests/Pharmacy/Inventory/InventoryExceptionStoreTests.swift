@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventoryExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventoryExceptionStore = Pharmacy.newMemoryInventoryExceptionStore()
        let item = Pharmacy.newInventoryException("code-120", label: "label-572")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
