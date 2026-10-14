@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolBudgetTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newScheduledFloatPoolBudget("code-958", title: "title-223")
        #expect(item.status == Staffing.ScheduledFloatPoolBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newScheduledFloatPoolBudget("code-958", title: "title-223")
        try item.moveTo(Staffing.ScheduledFloatPoolBudgetStatus.rejected)
        #expect(item.status == Staffing.ScheduledFloatPoolBudgetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newScheduledFloatPoolBudget("code-958", title: "title-223")
        item.status = Staffing.ScheduledFloatPoolBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ScheduledFloatPoolBudgetStatus.proposed) }
    }
}
