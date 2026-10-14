@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultConsentFormRequestEngine()
        let item = Consent.newConsentFormRequest("code-570", label: "label-876")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
