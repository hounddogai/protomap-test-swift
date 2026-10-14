@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInventoryAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultAdaptiveInventoryAuditEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newAdaptiveInventoryAudit("code-346", name: "name-605")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
