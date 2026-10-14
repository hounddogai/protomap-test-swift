@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryBatchedSpecimenSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.BatchedSpecimenSnapshotStore = Labs.newMemoryBatchedSpecimenSnapshotStore()
        let item = Labs.newBatchedSpecimenSnapshot("code-528", name: "name-954")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
