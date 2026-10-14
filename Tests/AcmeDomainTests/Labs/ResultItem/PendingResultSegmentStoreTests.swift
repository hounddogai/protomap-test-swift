@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryPendingResultSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.PendingResultSegmentStore = Labs.newMemoryPendingResultSegmentStore()
        let item = Labs.newPendingResultSegment("code-541", title: "title-352")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
