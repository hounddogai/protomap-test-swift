@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredLanguageTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultTieredLanguageTemplateEngine()
        let item = Consent.newTieredLanguageTemplate("code-516", title: "title-260")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
