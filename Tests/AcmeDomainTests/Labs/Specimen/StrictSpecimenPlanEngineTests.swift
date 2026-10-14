@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultStrictSpecimenPlanEngine(Kit.Flags.newRegistry())
        let item = Labs.newStrictSpecimenPlan("code-543", label: "label-212")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
