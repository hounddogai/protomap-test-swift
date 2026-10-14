@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRollupTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newBedBoardRollup("code-282", label: "label-223")
        #expect(item.status == BedManagement.BedBoardRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newBedBoardRollup("code-282", label: "label-223")
        try item.moveTo(BedManagement.BedBoardRollupStatus.suspended)
        #expect(item.status == BedManagement.BedBoardRollupStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newBedBoardRollup("code-282", label: "label-223")
        item.status = BedManagement.BedBoardRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardRollupStatus.draft) }
    }
}
