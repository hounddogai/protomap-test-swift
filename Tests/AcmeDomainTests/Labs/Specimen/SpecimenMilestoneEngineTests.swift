@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSpecimenMilestoneEngine()
        let item = Labs.newSpecimenMilestone("code-151", label: "label-707")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
