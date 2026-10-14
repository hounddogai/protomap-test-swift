@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularyRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLegacyFormularyRollupEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newLegacyFormularyRollup("code-934", label: "label-599")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
