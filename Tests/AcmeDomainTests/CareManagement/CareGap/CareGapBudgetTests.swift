@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBudgetTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newCareGapBudget("code-707", name: "name-632")
        #expect(item.status == CareManagement.CareGapBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newCareGapBudget("code-707", name: "name-632")
        try item.moveTo(CareManagement.CareGapBudgetStatus.queued)
        #expect(item.status == CareManagement.CareGapBudgetStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newCareGapBudget("code-707", name: "name-632")
        item.status = CareManagement.CareGapBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapBudgetStatus.new) }
    }
}
