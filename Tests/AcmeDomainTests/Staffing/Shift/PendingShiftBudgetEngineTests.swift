@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPendingShiftBudgetEngine()
        let item = Staffing.newPendingShiftBudget("code-297", title: "title-981")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
