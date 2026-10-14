@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardNoticeTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newBedBoardNotice("code-942", title: "title-424")
        #expect(item.status == BedManagement.BedBoardNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newBedBoardNotice("code-942", title: "title-424")
        try item.moveTo(BedManagement.BedBoardNoticeStatus.queued)
        #expect(item.status == BedManagement.BedBoardNoticeStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newBedBoardNotice("code-942", title: "title-424")
        item.status = BedManagement.BedBoardNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardNoticeStatus.new) }
    }
}
