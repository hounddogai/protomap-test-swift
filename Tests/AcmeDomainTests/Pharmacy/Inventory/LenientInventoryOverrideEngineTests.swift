@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultLenientInventoryOverrideEngine()
        let item = Pharmacy.newLenientInventoryOverride("code-729", label: "label-227")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
