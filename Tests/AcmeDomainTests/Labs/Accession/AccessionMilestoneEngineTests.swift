@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAccessionMilestoneEngine()
        let item = Labs.newAccessionMilestone("code-7", name: "name-844")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
