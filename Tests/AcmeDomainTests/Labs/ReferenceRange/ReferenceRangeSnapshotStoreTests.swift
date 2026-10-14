@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeSnapshotStore = Labs.newMemoryReferenceRangeSnapshotStore()
        let item = Labs.newReferenceRangeSnapshot("code-156", title: "title-520")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
