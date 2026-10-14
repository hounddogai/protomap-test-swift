@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLenientSpecimenMilestoneEngine()
        let item = Labs.newLenientSpecimenMilestone("code-847", label: "label-609")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
