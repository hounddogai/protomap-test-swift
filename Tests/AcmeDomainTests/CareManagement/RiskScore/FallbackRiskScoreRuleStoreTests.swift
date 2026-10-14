@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackRiskScoreRuleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackRiskScoreRuleStore = CareManagement.newMemoryFallbackRiskScoreRuleStore()
        let item = CareManagement.newFallbackRiskScoreRule("code-405", label: "label-313")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
