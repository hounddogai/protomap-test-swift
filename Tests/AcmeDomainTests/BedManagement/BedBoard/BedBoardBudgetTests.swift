@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBudgetTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newBedBoardBudget("code-93", name: "name-168")
        #expect(item.status == BedManagement.BedBoardBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newBedBoardBudget("code-93", name: "name-168")
        try item.moveTo(BedManagement.BedBoardBudgetStatus.expired)
        #expect(item.status == BedManagement.BedBoardBudgetStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newBedBoardBudget("code-93", name: "name-168")
        item.status = BedManagement.BedBoardBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardBudgetStatus.requested) }
    }
}
