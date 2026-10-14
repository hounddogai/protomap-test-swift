@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryInventorySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.InventorySnapshotStore = Pharmacy.newMemoryInventorySnapshotStore()
        let item = Pharmacy.newInventorySnapshot("code-311", label: "label-155")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
