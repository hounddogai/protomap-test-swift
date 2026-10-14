@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryBatchedCourierBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.BatchedCourierBatchStore = Labs.newMemoryBatchedCourierBatchStore()
        let item = Labs.newBatchedCourierBatch("code-250", label: "label-514")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
