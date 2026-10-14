@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryFloatPoolBudgetTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newPrimaryFloatPoolBudget("code-218", name: "name-570")
        #expect(item.status == Staffing.PrimaryFloatPoolBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newPrimaryFloatPoolBudget("code-218", name: "name-570")
        try item.moveTo(Staffing.PrimaryFloatPoolBudgetStatus.warming)
        #expect(item.status == Staffing.PrimaryFloatPoolBudgetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newPrimaryFloatPoolBudget("code-218", name: "name-570")
        item.status = Staffing.PrimaryFloatPoolBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryFloatPoolBudgetStatus.idle) }
    }
}
