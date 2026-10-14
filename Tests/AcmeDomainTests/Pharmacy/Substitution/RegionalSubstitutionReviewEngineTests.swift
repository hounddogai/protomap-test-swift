@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultRegionalSubstitutionReviewEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newRegionalSubstitutionReview("code-821", name: "name-30")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
