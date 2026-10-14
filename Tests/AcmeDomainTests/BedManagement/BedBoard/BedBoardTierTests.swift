@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardTierTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newBedBoardTier("code-554", title: "title-202")
        #expect(item.status == BedManagement.BedBoardTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = BedManagement.newBedBoardTier("code-554", title: "title-202")
        try item.moveTo(BedManagement.BedBoardTierStatus.stopped)
        #expect(item.status == BedManagement.BedBoardTierStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newBedBoardTier("code-554", title: "title-202")
        item.status = BedManagement.BedBoardTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardTierStatus.idle) }
    }
}
