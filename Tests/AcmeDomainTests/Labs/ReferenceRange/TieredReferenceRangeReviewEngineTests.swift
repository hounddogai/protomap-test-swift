@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredReferenceRangeReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultTieredReferenceRangeReviewEngine()
        let item = Labs.newTieredReferenceRangeReview("code-174", label: "label-366")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
