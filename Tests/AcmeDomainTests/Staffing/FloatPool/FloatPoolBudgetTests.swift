@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolBudgetTests {
    @Test func startsInNew() throws {
        let item = Staffing.newFloatPoolBudget("code-537", label: "label-573")
        #expect(item.status == Staffing.FloatPoolBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newFloatPoolBudget("code-537", label: "label-573")
        try item.moveTo(Staffing.FloatPoolBudgetStatus.running)
        #expect(item.status == Staffing.FloatPoolBudgetStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newFloatPoolBudget("code-537", label: "label-573")
        item.status = Staffing.FloatPoolBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolBudgetStatus.new) }
    }
}
