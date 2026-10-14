@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalDispenseEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultRegionalDispenseEstimateEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newRegionalDispenseEstimate("code-409", name: "name-588")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
