@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingQuotaStore = ClinicalOps.newMemoryRoundingQuotaStore()
        let item = ClinicalOps.newRoundingQuota("code-300", title: "title-236")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
