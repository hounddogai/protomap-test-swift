@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyProxyBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLegacyProxyBudgetEngine()
        let item = Consent.newLegacyProxyBudget("code-822", title: "title-696")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
