@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardDraftTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newBedBoardDraft("code-829", name: "name-159")
        #expect(item.status == BedManagement.BedBoardDraftStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newBedBoardDraft("code-829", name: "name-159")
        try item.moveTo(BedManagement.BedBoardDraftStatus.rejected)
        #expect(item.status == BedManagement.BedBoardDraftStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newBedBoardDraft("code-829", name: "name-159")
        item.status = BedManagement.BedBoardDraftStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardDraftStatus.proposed) }
    }
}
