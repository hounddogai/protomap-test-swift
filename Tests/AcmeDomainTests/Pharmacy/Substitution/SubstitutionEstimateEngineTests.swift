@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultSubstitutionEstimateEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newSubstitutionEstimate("code-10", name: "name-241")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
