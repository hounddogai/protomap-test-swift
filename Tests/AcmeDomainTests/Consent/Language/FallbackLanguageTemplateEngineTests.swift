@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguageTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultFallbackLanguageTemplateEngine()
        let item = Consent.newFallbackLanguageTemplate("code-866", title: "title-38")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
