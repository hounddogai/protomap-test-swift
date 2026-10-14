@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingOvertimeBudgetTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newRollingOvertimeBudget("code-87", title: "title-275")
        #expect(item.status == Staffing.RollingOvertimeBudgetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newRollingOvertimeBudget("code-87", title: "title-275")
        try item.moveTo(Staffing.RollingOvertimeBudgetStatus.warming)
        #expect(item.status == Staffing.RollingOvertimeBudgetStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newRollingOvertimeBudget("code-87", title: "title-275")
        item.status = Staffing.RollingOvertimeBudgetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingOvertimeBudgetStatus.idle) }
    }
}
