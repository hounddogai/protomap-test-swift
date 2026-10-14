@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultWeightedSpecimenProposalEngine(Kit.Flags.newRegistry())
        let item = Labs.newWeightedSpecimenProposal("code-53", title: "title-192")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
