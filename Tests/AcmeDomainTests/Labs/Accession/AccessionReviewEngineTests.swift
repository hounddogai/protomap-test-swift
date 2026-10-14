@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAccessionReviewEngine(Kit.Flags.newRegistry())
        let item = Labs.newAccessionReview("code-966", name: "name-453")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
