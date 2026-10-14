@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCensusBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultScheduledCensusBudgetEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newScheduledCensusBudget("code-97", name: "name-153")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
