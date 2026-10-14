@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertAgreementStore = ClinicalOps.newMemoryAlertAgreementStore()
        let item = ClinicalOps.newAlertAgreement("code-955", name: "name-671")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
