@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultManualConsentFormWindowEngine()
        let item = Consent.newManualConsentFormWindow("code-979", title: "title-603")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
