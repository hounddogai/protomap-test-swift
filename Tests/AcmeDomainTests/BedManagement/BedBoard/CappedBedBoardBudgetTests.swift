@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardBudgetTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newCappedBedBoardBudget("code-643", label: "label-977")
        #expect(item.status == BedManagement.CappedBedBoardBudgetStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newCappedBedBoardBudget("code-643", label: "label-977")
        try item.moveTo(BedManagement.CappedBedBoardBudgetStatus.done)
        #expect(item.status == BedManagement.CappedBedBoardBudgetStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newCappedBedBoardBudget("code-643", label: "label-977")
        item.status = BedManagement.CappedBedBoardBudgetStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedBedBoardBudgetStatus.new) }
    }
}
