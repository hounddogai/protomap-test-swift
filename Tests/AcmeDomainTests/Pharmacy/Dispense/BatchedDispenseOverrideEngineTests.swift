@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultBatchedDispenseOverrideEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newBatchedDispenseOverride("code-785", name: "name-538")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
