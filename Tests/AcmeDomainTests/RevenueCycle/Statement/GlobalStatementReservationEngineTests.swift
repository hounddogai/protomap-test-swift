@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalStatementReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultGlobalStatementReservationEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newGlobalStatementReservation("code-967", label: "label-602")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
