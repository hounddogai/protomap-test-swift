@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultGlobalInventoryWindowEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newGlobalInventoryWindow("code-64", label: "label-764")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
