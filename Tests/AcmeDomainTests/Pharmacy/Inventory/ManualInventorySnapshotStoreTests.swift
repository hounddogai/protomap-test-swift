@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryManualInventorySnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.ManualInventorySnapshotStore = Pharmacy.newMemoryManualInventorySnapshotStore()
        let item = Pharmacy.newManualInventorySnapshot("code-575", label: "label-908")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
