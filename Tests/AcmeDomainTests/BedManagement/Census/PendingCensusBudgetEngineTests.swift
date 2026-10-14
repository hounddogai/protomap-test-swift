@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultPendingCensusBudgetEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newPendingCensusBudget("code-252", name: "name-272")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
