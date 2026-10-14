@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingAccessionSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingAccessionSegmentStore = Labs.newMemoryRollingAccessionSegmentStore()
        let item = Labs.newRollingAccessionSegment("code-617", label: "label-608")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
