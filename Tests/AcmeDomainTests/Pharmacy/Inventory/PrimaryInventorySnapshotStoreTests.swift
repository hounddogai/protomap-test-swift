@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryPrimaryInventorySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.PrimaryInventorySnapshotStore = Pharmacy.newMemoryPrimaryInventorySnapshotStore()
        let item = Pharmacy.newPrimaryInventorySnapshot("code-273", label: "label-670")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
