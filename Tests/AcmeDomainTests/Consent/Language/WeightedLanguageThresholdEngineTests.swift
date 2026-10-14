@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedLanguageThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultWeightedLanguageThresholdEngine()
        let item = Consent.newWeightedLanguageThreshold("code-36", name: "name-697")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
