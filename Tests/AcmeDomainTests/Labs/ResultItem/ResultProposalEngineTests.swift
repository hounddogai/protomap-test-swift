@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultProposalEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultProposal("code-870", label: "label-867")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
