@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardDraftTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newStrictBedBoardDraft("code-337", label: "label-812")
        #expect(item.status == BedManagement.StrictBedBoardDraftStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newStrictBedBoardDraft("code-337", label: "label-812")
        try item.moveTo(BedManagement.StrictBedBoardDraftStatus.suspended)
        #expect(item.status == BedManagement.StrictBedBoardDraftStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newStrictBedBoardDraft("code-337", label: "label-812")
        item.status = BedManagement.StrictBedBoardDraftStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictBedBoardDraftStatus.draft) }
    }
}
