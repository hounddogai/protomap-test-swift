@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningBudgetTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newAdaptiveCleaningBudget("code-11", label: "label-445")
        #expect(item.status == BedManagement.AdaptiveCleaningBudgetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = BedManagement.newAdaptiveCleaningBudget("code-11", label: "label-445")
        try item.moveTo(BedManagement.AdaptiveCleaningBudgetStatus.published)
        #expect(item.status == BedManagement.AdaptiveCleaningBudgetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newAdaptiveCleaningBudget("code-11", label: "label-445")
        item.status = BedManagement.AdaptiveCleaningBudgetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveCleaningBudgetStatus.created) }
    }
}
