@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveDispenseReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultAdaptiveDispenseReviewEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newAdaptiveDispenseReview("code-906", label: "label-529")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
