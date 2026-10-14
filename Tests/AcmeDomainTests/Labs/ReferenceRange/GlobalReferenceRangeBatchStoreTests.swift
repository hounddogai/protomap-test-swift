@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalReferenceRangeBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalReferenceRangeBatchStore = Labs.newMemoryGlobalReferenceRangeBatchStore()
        let item = Labs.newGlobalReferenceRangeBatch("code-165", title: "title-306")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
