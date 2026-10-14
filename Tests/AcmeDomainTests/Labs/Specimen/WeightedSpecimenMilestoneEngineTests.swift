@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultWeightedSpecimenMilestoneEngine()
        let item = Labs.newWeightedSpecimenMilestone("code-7", name: "name-826")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
