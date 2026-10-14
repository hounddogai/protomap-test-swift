@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingConsentFormAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultPendingConsentFormAllocationEngine(Kit.Flags.newRegistry())
        let item = Consent.newPendingConsentFormAllocation("code-274", name: "name-626")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
