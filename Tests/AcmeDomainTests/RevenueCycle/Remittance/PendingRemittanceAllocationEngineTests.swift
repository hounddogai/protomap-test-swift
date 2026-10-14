@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingRemittanceAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultPendingRemittanceAllocationEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newPendingRemittanceAllocation("code-763", label: "label-846")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
