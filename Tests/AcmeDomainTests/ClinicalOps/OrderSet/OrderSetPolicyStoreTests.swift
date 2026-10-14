@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetPolicyStore = ClinicalOps.newMemoryOrderSetPolicyStore()
        let item = ClinicalOps.newOrderSetPolicy("code-7", label: "label-35")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
