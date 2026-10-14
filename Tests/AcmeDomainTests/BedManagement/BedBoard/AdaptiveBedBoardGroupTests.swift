@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardGroupTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newAdaptiveBedBoardGroup("code-421", title: "title-631")
        #expect(item.status == BedManagement.AdaptiveBedBoardGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newAdaptiveBedBoardGroup("code-421", title: "title-631")
        try item.moveTo(BedManagement.AdaptiveBedBoardGroupStatus.active)
        #expect(item.status == BedManagement.AdaptiveBedBoardGroupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newAdaptiveBedBoardGroup("code-421", title: "title-631")
        item.status = BedManagement.AdaptiveBedBoardGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveBedBoardGroupStatus.draft) }
    }
}
