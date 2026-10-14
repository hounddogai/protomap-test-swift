@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingRiskScoreRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRollingRiskScoreRuleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRollingRiskScoreRule("code-879", title: "title-348")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
