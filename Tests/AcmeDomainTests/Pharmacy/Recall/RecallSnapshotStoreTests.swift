@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryRecallSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.RecallSnapshotStore = Pharmacy.newMemoryRecallSnapshotStore()
        let item = Pharmacy.newRecallSnapshot("code-648", name: "name-473")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
