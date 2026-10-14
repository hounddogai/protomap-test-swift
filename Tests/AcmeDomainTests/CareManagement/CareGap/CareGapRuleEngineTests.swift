@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultCareGapRuleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newCareGapRule("code-123", name: "name-904")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
