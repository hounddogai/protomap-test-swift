@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultFormularyRuleEngine()
        let item = Pharmacy.newFormularyRule("code-394", name: "name-3")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
