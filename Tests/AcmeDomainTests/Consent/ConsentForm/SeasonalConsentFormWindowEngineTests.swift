@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalConsentFormWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultSeasonalConsentFormWindowEngine()
        let item = Consent.newSeasonalConsentFormWindow("code-362", title: "title-429")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
