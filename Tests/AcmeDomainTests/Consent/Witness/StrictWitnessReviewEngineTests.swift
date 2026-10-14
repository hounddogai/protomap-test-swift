@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictWitnessReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultStrictWitnessReviewEngine(Kit.Flags.newRegistry())
        let item = Consent.newStrictWitnessReview("code-976", label: "label-764")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
