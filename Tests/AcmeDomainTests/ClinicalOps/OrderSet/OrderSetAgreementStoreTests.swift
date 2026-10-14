@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetAgreementStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetAgreementStore = ClinicalOps.newMemoryOrderSetAgreementStore()
        let item = ClinicalOps.newOrderSetAgreement("code-614", title: "title-766")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
