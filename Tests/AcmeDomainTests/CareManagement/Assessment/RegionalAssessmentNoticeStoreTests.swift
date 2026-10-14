@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRegionalAssessmentNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RegionalAssessmentNoticeStore = CareManagement.newMemoryRegionalAssessmentNoticeStore()
        let item = CareManagement.newRegionalAssessmentNotice("code-189", label: "label-231")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
