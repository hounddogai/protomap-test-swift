@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultConsentFormVarianceEngine()
        let item = Consent.newConsentFormVariance("code-851", label: "label-196")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
