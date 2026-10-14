@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBaselineTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newBedBoardBaseline("code-964", label: "label-888")
        #expect(item.status == BedManagement.BedBoardBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = BedManagement.newBedBoardBaseline("code-964", label: "label-888")
        try item.moveTo(BedManagement.BedBoardBaselineStatus.closed)
        #expect(item.status == BedManagement.BedBoardBaselineStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newBedBoardBaseline("code-964", label: "label-888")
        item.status = BedManagement.BedBoardBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardBaselineStatus.draft) }
    }
}
