@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRegionalAssessmentScoreEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRegionalAssessmentScore("code-578", name: "name-939")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
