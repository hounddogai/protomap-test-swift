@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguagePreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLanguagePreferenceEngine(Kit.Flags.newRegistry())
        let item = Consent.newLanguagePreference("code-546", title: "title-350")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
