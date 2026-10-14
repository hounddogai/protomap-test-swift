@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachNoticeStore = CareManagement.newMemoryOutreachNoticeStore()
        let item = CareManagement.newOutreachNotice("code-247", label: "label-595")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
