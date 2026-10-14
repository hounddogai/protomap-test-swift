@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalReferenceRangeSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalReferenceRangeSegmentStore = Labs.newMemoryGlobalReferenceRangeSegmentStore()
        let item = Labs.newGlobalReferenceRangeSegment("code-324", label: "label-439")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
