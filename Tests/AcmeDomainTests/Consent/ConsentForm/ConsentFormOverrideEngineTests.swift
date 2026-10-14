@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultConsentFormOverrideEngine()
        let item = Consent.newConsentFormOverride("code-66", label: "label-474")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
