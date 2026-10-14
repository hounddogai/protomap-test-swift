@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCappedResultSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CappedResultSegmentStore = Labs.newMemoryCappedResultSegmentStore()
        let item = Labs.newCappedResultSegment("code-493", label: "label-917")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
