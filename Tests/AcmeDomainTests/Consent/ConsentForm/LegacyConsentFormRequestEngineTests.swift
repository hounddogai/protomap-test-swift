@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyConsentFormRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLegacyConsentFormRequestEngine(Kit.Flags.newRegistry())
        let item = Consent.newLegacyConsentFormRequest("code-929", label: "label-321")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
