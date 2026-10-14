@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierReviewEngine()
        let item = Labs.newCourierReview("code-625", name: "name-631")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
