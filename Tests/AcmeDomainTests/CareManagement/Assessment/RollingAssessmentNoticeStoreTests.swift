@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRollingAssessmentNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RollingAssessmentNoticeStore = CareManagement.newMemoryRollingAssessmentNoticeStore()
        let item = CareManagement.newRollingAssessmentNotice("code-419", title: "title-179")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
