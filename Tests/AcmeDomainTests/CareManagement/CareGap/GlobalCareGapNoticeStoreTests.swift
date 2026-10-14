@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalCareGapNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalCareGapNoticeStore = CareManagement.newMemoryGlobalCareGapNoticeStore()
        let item = CareManagement.newGlobalCareGapNotice("code-694", name: "name-551")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
