@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLegacyDisclosureAgreementEngine(Kit.Flags.newRegistry())
        let item = Consent.newLegacyDisclosureAgreement("code-873", title: "title-840")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
