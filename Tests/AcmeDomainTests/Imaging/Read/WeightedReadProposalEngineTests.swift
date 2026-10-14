@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedReadProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultWeightedReadProposalEngine()
        let item = Imaging.newWeightedReadProposal("code-118", label: "label-665")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
