@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultAdaptiveConsentFormReviewEngine()
        let item = Consent.newAdaptiveConsentFormReview("code-815", name: "name-450")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
