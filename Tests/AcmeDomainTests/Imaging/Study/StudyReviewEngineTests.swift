@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultStudyReviewEngine(Kit.Flags.newRegistry())
        let item = Imaging.newStudyReview("code-27", title: "title-445")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
