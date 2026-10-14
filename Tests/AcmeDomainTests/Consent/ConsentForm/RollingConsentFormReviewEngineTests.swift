@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingConsentFormReviewEngine()
        let item = Consent.newRollingConsentFormReview("code-581", title: "title-665")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
