@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolPolicyStore = ClinicalOps.newMemoryCareProtocolPolicyStore()
        let item = ClinicalOps.newCareProtocolPolicy("code-346", label: "label-200")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
