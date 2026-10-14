@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertQuotaStore = ClinicalOps.newMemoryAlertQuotaStore()
        let item = ClinicalOps.newAlertQuota("code-157", name: "name-488")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
