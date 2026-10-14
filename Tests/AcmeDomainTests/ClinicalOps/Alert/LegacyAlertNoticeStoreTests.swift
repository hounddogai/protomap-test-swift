@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyAlertNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyAlertNoticeStore = ClinicalOps.newMemoryLegacyAlertNoticeStore()
        let item = ClinicalOps.newLegacyAlertNotice("code-108", name: "name-702")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
