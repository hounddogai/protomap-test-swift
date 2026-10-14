@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackCourierSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackCourierSegmentStore = Labs.newMemoryFallbackCourierSegmentStore()
        let item = Labs.newFallbackCourierSegment("code-828", title: "title-294")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
