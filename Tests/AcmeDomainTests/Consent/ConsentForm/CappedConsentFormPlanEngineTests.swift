@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultCappedConsentFormPlanEngine(Kit.Flags.newRegistry())
        let item = Consent.newCappedConsentFormPlan("code-914", title: "title-549")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
