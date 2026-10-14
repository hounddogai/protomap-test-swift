@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardScoreTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newBedBoardScore("code-99", title: "title-120")
        #expect(item.status == BedManagement.BedBoardScoreStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newBedBoardScore("code-99", title: "title-120")
        try item.moveTo(BedManagement.BedBoardScoreStatus.approved)
        #expect(item.status == BedManagement.BedBoardScoreStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newBedBoardScore("code-99", title: "title-120")
        item.status = BedManagement.BedBoardScoreStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardScoreStatus.proposed) }
    }
}
