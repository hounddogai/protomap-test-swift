@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSeasonalSpecimenMilestoneEngine(Kit.Flags.newRegistry())
        let item = Labs.newSeasonalSpecimenMilestone("code-429", title: "title-545")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
