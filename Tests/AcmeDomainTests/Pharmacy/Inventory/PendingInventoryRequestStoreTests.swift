@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingInventoryRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingInventoryRequestStore = Pharmacy.newMemoryPendingInventoryRequestStore()
        let item = Pharmacy.newPendingInventoryRequest("code-915", title: "title-17")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
