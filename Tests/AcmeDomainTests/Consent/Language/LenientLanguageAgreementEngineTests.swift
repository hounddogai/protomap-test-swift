@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientLanguageAgreementEngine(Kit.Flags.newRegistry())
        let item = Consent.newLenientLanguageAgreement("code-857", title: "title-49")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
