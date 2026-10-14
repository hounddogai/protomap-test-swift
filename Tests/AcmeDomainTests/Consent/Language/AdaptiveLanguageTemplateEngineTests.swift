@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveLanguageTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultAdaptiveLanguageTemplateEngine()
        let item = Consent.newAdaptiveLanguageTemplate("code-528", title: "title-921")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
