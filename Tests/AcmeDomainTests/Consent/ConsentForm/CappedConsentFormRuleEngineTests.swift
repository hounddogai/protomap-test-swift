@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedConsentFormRuleEngine(Kit.Flags.newRegistry())
        let item = Consent.newCappedConsentFormRule("code-799", name: "name-259")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
