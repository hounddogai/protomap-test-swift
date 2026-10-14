@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedInventoryRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedInventoryRequestStore = Pharmacy.newMemoryCappedInventoryRequestStore()
        let item = Pharmacy.newCappedInventoryRequest("code-408", label: "label-965")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
