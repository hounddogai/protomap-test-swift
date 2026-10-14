@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultInventoryThresholdEngine()
        let item = Pharmacy.newInventoryThreshold("code-360", title: "title-235")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
