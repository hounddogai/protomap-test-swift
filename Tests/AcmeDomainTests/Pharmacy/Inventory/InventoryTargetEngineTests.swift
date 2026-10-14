@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultInventoryTargetEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newInventoryTarget("code-762", name: "name-344")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
