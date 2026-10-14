@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryScheduledOutreachAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ScheduledOutreachAgreementStore = CareManagement.newMemoryScheduledOutreachAgreementStore()
        let item = CareManagement.newScheduledOutreachAgreement("code-479", title: "title-802")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
