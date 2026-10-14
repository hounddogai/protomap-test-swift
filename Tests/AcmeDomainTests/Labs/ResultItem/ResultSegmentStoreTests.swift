@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryResultSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ResultSegmentStore = Labs.newMemoryResultSegmentStore()
        let item = Labs.newResultSegment("code-457", label: "label-798")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
