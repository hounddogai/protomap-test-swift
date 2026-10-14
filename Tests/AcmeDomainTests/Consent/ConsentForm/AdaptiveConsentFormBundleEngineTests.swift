@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultAdaptiveConsentFormBundleEngine(Kit.Flags.newRegistry())
        let item = Consent.newAdaptiveConsentFormBundle("code-844", title: "title-457")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
