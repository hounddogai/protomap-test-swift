@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedLanguageRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWeightedLanguageRequestEngine()
        let item = Consent.newWeightedLanguageRequest("code-103", title: "title-134")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
