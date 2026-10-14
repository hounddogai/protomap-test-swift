@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictRecallReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultStrictRecallReviewEngine()
        let item = Pharmacy.newStrictRecallReview("code-784", label: "label-77")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
