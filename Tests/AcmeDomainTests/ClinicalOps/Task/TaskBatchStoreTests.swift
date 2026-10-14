@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskBatchStore = ClinicalOps.newMemoryTaskBatchStore()
        let item = ClinicalOps.newTaskBatch("code-546", name: "name-295")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
