@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingCensusBudgetTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newPendingCensusBudget("code-252", name: "name-272")
        #expect(item.status == BedManagement.PendingCensusBudgetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newPendingCensusBudget("code-252", name: "name-272")
        try item.moveTo(BedManagement.PendingCensusBudgetStatus.rejected)
        #expect(item.status == BedManagement.PendingCensusBudgetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newPendingCensusBudget("code-252", name: "name-272")
        item.status = BedManagement.PendingCensusBudgetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PendingCensusBudgetStatus.proposed) }
    }
}
