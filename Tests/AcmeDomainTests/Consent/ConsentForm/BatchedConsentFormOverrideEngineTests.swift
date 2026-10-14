@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedConsentFormOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultBatchedConsentFormOverrideEngine()
        let item = Consent.newBatchedConsentFormOverride("code-957", title: "title-627")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
