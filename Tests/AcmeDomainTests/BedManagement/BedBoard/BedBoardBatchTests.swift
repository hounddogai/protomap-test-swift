@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBatchTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBedBoardBatch("code-926", title: "title-957")
        #expect(item.status == BedManagement.BedBoardBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newBedBoardBatch("code-926", title: "title-957")
        try item.moveTo(BedManagement.BedBoardBatchStatus.scheduled)
        #expect(item.status == BedManagement.BedBoardBatchStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBedBoardBatch("code-926", title: "title-957")
        item.status = BedManagement.BedBoardBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardBatchStatus.planned) }
    }
}
