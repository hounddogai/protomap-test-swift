@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardProfileTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newBedBoardProfile("code-177", name: "name-267")
        #expect(item.status == BedManagement.BedBoardProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = BedManagement.newBedBoardProfile("code-177", name: "name-267")
        try item.moveTo(BedManagement.BedBoardProfileStatus.draining)
        #expect(item.status == BedManagement.BedBoardProfileStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newBedBoardProfile("code-177", name: "name-267")
        item.status = BedManagement.BedBoardProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardProfileStatus.idle) }
    }
}
