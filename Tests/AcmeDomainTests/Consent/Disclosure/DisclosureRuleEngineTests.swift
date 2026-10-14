@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultDisclosureRuleEngine()
        let item = Consent.newDisclosureRule("code-361", label: "label-765")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
