@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultBatchedTaskPlanEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newBatchedTaskPlan("code-562", label: "label-243")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
