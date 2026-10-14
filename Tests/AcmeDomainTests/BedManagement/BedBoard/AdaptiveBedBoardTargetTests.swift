@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveBedBoardTargetTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newAdaptiveBedBoardTarget("code-375", title: "title-319")
        #expect(item.status == BedManagement.AdaptiveBedBoardTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = BedManagement.newAdaptiveBedBoardTarget("code-375", title: "title-319")
        try item.moveTo(BedManagement.AdaptiveBedBoardTargetStatus.retired)
        #expect(item.status == BedManagement.AdaptiveBedBoardTargetStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newAdaptiveBedBoardTarget("code-375", title: "title-319")
        item.status = BedManagement.AdaptiveBedBoardTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveBedBoardTargetStatus.created) }
    }
}
