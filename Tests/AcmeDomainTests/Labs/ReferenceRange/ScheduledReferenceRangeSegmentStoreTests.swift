@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledReferenceRangeSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledReferenceRangeSegmentStore = Labs.newMemoryScheduledReferenceRangeSegmentStore()
        let item = Labs.newScheduledReferenceRangeSegment("code-32", name: "name-372")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
