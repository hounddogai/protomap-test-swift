@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultReferenceRangeSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultReferenceRangeSegmentStore = Labs.newMemoryDefaultReferenceRangeSegmentStore()
        let item = Labs.newDefaultReferenceRangeSegment("code-237", label: "label-245")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
