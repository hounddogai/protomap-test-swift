@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertNoticeStore = ClinicalOps.newMemoryAlertNoticeStore()
        let item = ClinicalOps.newAlertNotice("code-143", name: "name-204")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
