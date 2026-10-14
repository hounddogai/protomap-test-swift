@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingRuleStore = ClinicalOps.newMemoryRoundingRuleStore()
        let item = ClinicalOps.newRoundingRule("code-575", label: "label-833")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
