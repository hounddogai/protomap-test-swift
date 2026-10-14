@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRollingAlertNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RollingAlertNoticeStore = ClinicalOps.newMemoryRollingAlertNoticeStore()
        let item = ClinicalOps.newRollingAlertNotice("code-833", name: "name-119")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
