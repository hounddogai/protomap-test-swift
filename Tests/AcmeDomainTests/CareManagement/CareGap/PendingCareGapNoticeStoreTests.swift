@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryPendingCareGapNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.PendingCareGapNoticeStore = CareManagement.newMemoryPendingCareGapNoticeStore()
        let item = CareManagement.newPendingCareGapNotice("code-86", label: "label-329")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
