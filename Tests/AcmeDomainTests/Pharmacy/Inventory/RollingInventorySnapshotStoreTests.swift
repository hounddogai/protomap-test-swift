@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRollingInventorySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RollingInventorySnapshotStore = Pharmacy.newMemoryRollingInventorySnapshotStore()
        let item = Pharmacy.newRollingInventorySnapshot("code-146", title: "title-297")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
