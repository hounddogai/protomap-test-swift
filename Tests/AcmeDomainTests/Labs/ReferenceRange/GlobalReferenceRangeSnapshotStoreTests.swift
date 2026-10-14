@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalReferenceRangeSnapshotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalReferenceRangeSnapshotStore = Labs.newMemoryGlobalReferenceRangeSnapshotStore()
        let item = Labs.newGlobalReferenceRangeSnapshot("code-727", label: "label-70")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
