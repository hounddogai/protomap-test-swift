@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInventoryRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultStrictInventoryRollupEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newStrictInventoryRollup("code-645", title: "title-748")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
