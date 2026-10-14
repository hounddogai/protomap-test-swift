@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultConsentFormBudgetEngine(Kit.Flags.newRegistry())
        let item = Consent.newConsentFormBudget("code-735", name: "name-251")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
