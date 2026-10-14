@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictConsentFormWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultStrictConsentFormWindowEngine(Kit.Flags.newRegistry())
        let item = Consent.newStrictConsentFormWindow("code-846", name: "name-583")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
