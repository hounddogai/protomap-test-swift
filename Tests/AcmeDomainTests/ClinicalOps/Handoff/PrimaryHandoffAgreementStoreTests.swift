@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryHandoffAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryHandoffAgreementStore = ClinicalOps.newMemoryPrimaryHandoffAgreementStore()
        let item = ClinicalOps.newPrimaryHandoffAgreement("code-172", title: "title-100")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
