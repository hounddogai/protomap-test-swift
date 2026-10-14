@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultFallbackFormularyReviewEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newFallbackFormularyReview("code-408", name: "name-158")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
