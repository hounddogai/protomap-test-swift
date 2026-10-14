@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalFormularyMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultRegionalFormularyMilestoneEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newRegionalFormularyMilestone("code-526", label: "label-490")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
