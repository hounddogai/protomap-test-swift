@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedAccessionPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultBatchedAccessionPlanEngine()
        let item = Labs.newBatchedAccessionPlan("code-771", title: "title-890")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
