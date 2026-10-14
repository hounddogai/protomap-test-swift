@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardThresholdTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newBedBoardThreshold("code-874", title: "title-928")
        #expect(item.status == BedManagement.BedBoardThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newBedBoardThreshold("code-874", title: "title-928")
        try item.moveTo(BedManagement.BedBoardThresholdStatus.draining)
        #expect(item.status == BedManagement.BedBoardThresholdStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newBedBoardThreshold("code-874", title: "title-928")
        item.status = BedManagement.BedBoardThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardThresholdStatus.idle) }
    }
}
