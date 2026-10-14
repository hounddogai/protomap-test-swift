@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardRequestTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newBedBoardRequest("code-29", name: "name-113")
        #expect(item.status == BedManagement.BedBoardRequestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newBedBoardRequest("code-29", name: "name-113")
        try item.moveTo(BedManagement.BedBoardRequestStatus.scheduled)
        #expect(item.status == BedManagement.BedBoardRequestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newBedBoardRequest("code-29", name: "name-113")
        item.status = BedManagement.BedBoardRequestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardRequestStatus.planned) }
    }
}
