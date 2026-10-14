@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultWeightedFormularyGroupEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newWeightedFormularyGroup("code-709", label: "label-841")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
