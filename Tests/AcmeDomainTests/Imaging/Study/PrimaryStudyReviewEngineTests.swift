@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrimaryStudyReviewEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPrimaryStudyReview("code-256", label: "label-867")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
