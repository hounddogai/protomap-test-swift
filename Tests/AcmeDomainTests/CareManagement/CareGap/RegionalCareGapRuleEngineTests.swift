@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRegionalCareGapRuleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRegionalCareGapRule("code-741", title: "title-654")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
