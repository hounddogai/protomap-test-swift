@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedCareProtocolQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedCareProtocolQuotaStore = ClinicalOps.newMemoryCappedCareProtocolQuotaStore()
        let item = ClinicalOps.newCappedCareProtocolQuota("code-753", label: "label-426")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
