@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingConsentFormWindowEngine(Kit.Flags.newRegistry())
        let item = Consent.newRollingConsentFormWindow("code-122", title: "title-208")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
