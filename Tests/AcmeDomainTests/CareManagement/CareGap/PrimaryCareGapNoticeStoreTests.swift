@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPrimaryCareGapNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PrimaryCareGapNoticeStore = CareManagement.newMemoryPrimaryCareGapNoticeStore()
        let item = CareManagement.newPrimaryCareGapNotice("code-940", name: "name-405")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
