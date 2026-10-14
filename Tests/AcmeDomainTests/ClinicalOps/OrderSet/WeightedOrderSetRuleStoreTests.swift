@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryWeightedOrderSetRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.WeightedOrderSetRuleStore = ClinicalOps.newMemoryWeightedOrderSetRuleStore()
        let item = ClinicalOps.newWeightedOrderSetRule("code-148", name: "name-751")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
