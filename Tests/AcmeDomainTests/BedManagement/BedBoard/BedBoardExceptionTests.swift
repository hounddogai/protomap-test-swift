@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardExceptionTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newBedBoardException("code-240", label: "label-971")
        #expect(item.status == BedManagement.BedBoardExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newBedBoardException("code-240", label: "label-971")
        try item.moveTo(BedManagement.BedBoardExceptionStatus.warming)
        #expect(item.status == BedManagement.BedBoardExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newBedBoardException("code-240", label: "label-971")
        item.status = BedManagement.BedBoardExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardExceptionStatus.idle) }
    }
}
