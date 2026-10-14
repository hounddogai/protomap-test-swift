@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryBatchedReferenceRangeRecordStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.BatchedReferenceRangeRecordStore = Labs.newMemoryBatchedReferenceRangeRecordStore()
        let item = Labs.newBatchedReferenceRangeRecord("code-576", title: "title-512")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
