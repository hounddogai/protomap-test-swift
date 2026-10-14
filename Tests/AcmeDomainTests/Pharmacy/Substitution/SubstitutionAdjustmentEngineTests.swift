@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultSubstitutionAdjustmentEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newSubstitutionAdjustment("code-702", label: "label-946")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
