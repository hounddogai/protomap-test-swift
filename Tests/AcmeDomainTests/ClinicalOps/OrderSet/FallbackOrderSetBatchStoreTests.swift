@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackOrderSetBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackOrderSetBatchStore = ClinicalOps.newMemoryFallbackOrderSetBatchStore()
        let item = ClinicalOps.newFallbackOrderSetBatch("code-273", label: "label-769")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
