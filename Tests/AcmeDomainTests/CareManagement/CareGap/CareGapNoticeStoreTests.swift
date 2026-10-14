@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapNoticeStore = CareManagement.newMemoryCareGapNoticeStore()
        let item = CareManagement.newCareGapNotice("code-904", name: "name-513")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
