@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventoryEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultManualInventoryEntryEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newManualInventoryEntry("code-157", name: "name-478")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
