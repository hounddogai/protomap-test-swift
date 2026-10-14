@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapAgreementStore = CareManagement.newMemoryCareGapAgreementStore()
        let item = CareManagement.newCareGapAgreement("code-328", title: "title-878")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
