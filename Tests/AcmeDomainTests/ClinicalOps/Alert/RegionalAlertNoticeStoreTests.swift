@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalAlertNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalAlertNoticeStore = ClinicalOps.newMemoryRegionalAlertNoticeStore()
        let item = ClinicalOps.newRegionalAlertNotice("code-369", label: "label-865")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
