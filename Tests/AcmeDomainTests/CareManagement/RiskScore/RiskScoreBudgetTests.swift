@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreBudgetTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRiskScoreBudget("code-9", name: "name-267")
        #expect(item.status == CareManagement.RiskScoreBudgetStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newRiskScoreBudget("code-9", name: "name-267")
        try item.moveTo(CareManagement.RiskScoreBudgetStatus.scheduled)
        #expect(item.status == CareManagement.RiskScoreBudgetStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRiskScoreBudget("code-9", name: "name-267")
        item.status = CareManagement.RiskScoreBudgetStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreBudgetStatus.planned) }
    }
}
