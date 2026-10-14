@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryManualOutreachAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ManualOutreachAgreementStore = CareManagement.newMemoryManualOutreachAgreementStore()
        let item = CareManagement.newManualOutreachAgreement("code-368", label: "label-128")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
