@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryBatchedCareProtocolQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.BatchedCareProtocolQuotaStore = ClinicalOps.newMemoryBatchedCareProtocolQuotaStore()
        let item = ClinicalOps.newBatchedCareProtocolQuota("code-604", label: "label-790")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
