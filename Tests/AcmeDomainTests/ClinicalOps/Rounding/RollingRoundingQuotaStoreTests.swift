@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingRoundingQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingRoundingQuotaStore = ClinicalOps.newMemoryRollingRoundingQuotaStore()
        let item = ClinicalOps.newRollingRoundingQuota("code-129", name: "name-253")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
