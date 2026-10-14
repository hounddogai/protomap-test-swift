@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingSpecimenProposalEngine()
        let item = Labs.newRollingSpecimenProposal("code-595", name: "name-678")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
