@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultReadProposalEngine()
        let item = Imaging.newReadProposal("code-407", name: "name-145")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
