@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalConsentFormTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultGlobalConsentFormTierEngine(Kit.Flags.newRegistry())
        let item = Consent.newGlobalConsentFormTier("code-999", name: "name-348")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
