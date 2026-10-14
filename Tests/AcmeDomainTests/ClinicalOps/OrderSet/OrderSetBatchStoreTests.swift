@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetBatchStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetBatchStore = ClinicalOps.newMemoryOrderSetBatchStore()
        let item = ClinicalOps.newOrderSetBatch("code-87", name: "name-416")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
