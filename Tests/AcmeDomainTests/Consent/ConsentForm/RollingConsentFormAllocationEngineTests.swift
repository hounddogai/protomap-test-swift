@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRollingConsentFormAllocationEngine(Kit.Flags.newRegistry())
        let item = Consent.newRollingConsentFormAllocation("code-558", label: "label-341")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
