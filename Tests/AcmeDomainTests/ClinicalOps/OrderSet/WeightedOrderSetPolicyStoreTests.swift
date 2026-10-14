@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryWeightedOrderSetPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.WeightedOrderSetPolicyStore = ClinicalOps.newMemoryWeightedOrderSetPolicyStore()
        let item = ClinicalOps.newWeightedOrderSetPolicy("code-605", label: "label-209")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
