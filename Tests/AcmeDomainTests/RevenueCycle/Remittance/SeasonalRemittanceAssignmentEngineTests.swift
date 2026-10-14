@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleSeasonalRemittanceAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultSeasonalRemittanceAssignmentEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newSeasonalRemittanceAssignment("code-420", label: "label-62")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
