@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryScheduledInventorySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ScheduledInventorySnapshotStore = Pharmacy.newMemoryScheduledInventorySnapshotStore()
        let item = Pharmacy.newScheduledInventorySnapshot("code-331", title: "title-204")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
