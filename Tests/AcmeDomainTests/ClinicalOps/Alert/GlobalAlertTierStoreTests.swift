@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalAlertTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalAlertTierStore = ClinicalOps.newMemoryGlobalAlertTierStore()
        let item = ClinicalOps.newGlobalAlertTier("code-28", title: "title-308")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
