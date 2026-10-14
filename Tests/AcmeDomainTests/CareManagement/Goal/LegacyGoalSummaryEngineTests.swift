@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyGoalSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLegacyGoalSummaryEngine()
        let item = CareManagement.newLegacyGoalSummary("code-168", title: "title-985")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
