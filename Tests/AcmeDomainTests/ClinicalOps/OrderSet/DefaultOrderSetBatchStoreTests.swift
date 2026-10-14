@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultOrderSetBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultOrderSetBatchStore = ClinicalOps.newMemoryDefaultOrderSetBatchStore()
        let item = ClinicalOps.newDefaultOrderSetBatch("code-416", label: "label-831")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
