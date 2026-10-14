@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultTaskBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultTaskBatchStore = ClinicalOps.newMemoryDefaultTaskBatchStore()
        let item = ClinicalOps.newDefaultTaskBatch("code-987", title: "title-97")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
