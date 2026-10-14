@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyMemoryCappedRecallSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Pharmacy.CappedRecallSnapshotStore = Pharmacy.newMemoryCappedRecallSnapshotStore()
        let item = Pharmacy.newCappedRecallSnapshot("code-732", name: "name-719")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
