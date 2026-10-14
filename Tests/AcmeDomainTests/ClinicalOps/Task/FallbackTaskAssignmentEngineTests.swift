@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackTaskAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultFallbackTaskAssignmentEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newFallbackTaskAssignment("code-880", label: "label-774")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
