@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLenientSubstitutionRollupEngine()
        let item = Pharmacy.newLenientSubstitutionRollup("code-6", label: "label-469")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
