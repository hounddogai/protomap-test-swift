@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingInteractionAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPendingInteractionAllocationEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newPendingInteractionAllocation("code-109", label: "label-365")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
