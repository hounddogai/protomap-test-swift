@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionBatchStore = Labs.newMemoryAccessionBatchStore()
        let item = Labs.newAccessionBatch("code-172", title: "title-862")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
