@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultScheduledConsentFormAllocationEngine(Kit.Flags.newRegistry())
        let item = Consent.newScheduledConsentFormAllocation("code-945", label: "label-165")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
