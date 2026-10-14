@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingAccessionBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingAccessionBatchStore = Labs.newMemoryRollingAccessionBatchStore()
        let item = Labs.newRollingAccessionBatch("code-14", title: "title-90")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
