@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertPolicyStore = ClinicalOps.newMemoryAlertPolicyStore()
        let item = ClinicalOps.newAlertPolicy("code-202", name: "name-52")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
