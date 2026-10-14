@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalCareProtocolQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalCareProtocolQuotaStore = ClinicalOps.newMemoryRegionalCareProtocolQuotaStore()
        let item = ClinicalOps.newRegionalCareProtocolQuota("code-900", name: "name-909")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
