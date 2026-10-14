@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingAlertQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingAlertQuotaStore = ClinicalOps.newMemoryPendingAlertQuotaStore()
        let item = ClinicalOps.newPendingAlertQuota("code-152", title: "title-269")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
