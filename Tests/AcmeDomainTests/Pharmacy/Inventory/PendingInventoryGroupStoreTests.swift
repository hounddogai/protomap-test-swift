@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPendingInventoryGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PendingInventoryGroupStore = Pharmacy.newMemoryPendingInventoryGroupStore()
        let item = Pharmacy.newPendingInventoryGroup("code-59", title: "title-764")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
