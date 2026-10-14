@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRiskScoreRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RiskScoreRuleStore = CareManagement.newMemoryRiskScoreRuleStore()
        let item = CareManagement.newRiskScoreRule("code-538", label: "label-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
