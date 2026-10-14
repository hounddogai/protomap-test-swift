@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardEstimateTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newBedBoardEstimate("code-599", title: "title-635")
        #expect(item.status == BedManagement.BedBoardEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newBedBoardEstimate("code-599", title: "title-635")
        try item.moveTo(BedManagement.BedBoardEstimateStatus.active)
        #expect(item.status == BedManagement.BedBoardEstimateStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newBedBoardEstimate("code-599", title: "title-635")
        item.status = BedManagement.BedBoardEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardEstimateStatus.draft) }
    }
}
