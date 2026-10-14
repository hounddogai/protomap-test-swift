@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingPanelPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingPanelPlanEngine()
        let item = Labs.newRollingPanelPlan("code-467", label: "label-974")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
