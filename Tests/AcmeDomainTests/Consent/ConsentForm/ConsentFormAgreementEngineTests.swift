@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultConsentFormAgreementEngine(Kit.Flags.newRegistry())
        let item = Consent.newConsentFormAgreement("code-923", name: "name-19")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
