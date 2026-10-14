@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultTaskPlanEngine()
        let item = ClinicalOps.newTaskPlan("code-785", label: "label-708")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
