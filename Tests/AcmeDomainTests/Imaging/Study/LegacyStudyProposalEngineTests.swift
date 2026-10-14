@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyStudyProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultLegacyStudyProposalEngine()
        let item = Imaging.newLegacyStudyProposal("code-460", label: "label-813")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
