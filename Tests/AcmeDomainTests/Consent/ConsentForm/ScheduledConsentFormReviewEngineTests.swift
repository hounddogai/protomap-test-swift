@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormReviewEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultScheduledConsentFormReviewEngine()
        let item = Consent.newScheduledConsentFormReview("code-205", name: "name-823")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
