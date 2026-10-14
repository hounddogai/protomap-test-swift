@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalOutreachAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalOutreachAgreementStore = CareManagement.newMemoryGlobalOutreachAgreementStore()
        let item = CareManagement.newGlobalOutreachAgreement("code-992", title: "title-52")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
