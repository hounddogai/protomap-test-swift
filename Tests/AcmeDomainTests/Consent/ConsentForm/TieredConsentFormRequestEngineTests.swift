@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredConsentFormRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultTieredConsentFormRequestEngine(Kit.Flags.newRegistry())
        let item = Consent.newTieredConsentFormRequest("code-9", label: "label-632")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
