@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedBedBoardGroupTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCappedBedBoardGroup("code-267", label: "label-170")
        #expect(item.status == BedManagement.CappedBedBoardGroupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newCappedBedBoardGroup("code-267", label: "label-170")
        try item.moveTo(BedManagement.CappedBedBoardGroupStatus.scheduled)
        #expect(item.status == BedManagement.CappedBedBoardGroupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCappedBedBoardGroup("code-267", label: "label-170")
        item.status = BedManagement.CappedBedBoardGroupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedBedBoardGroupStatus.planned) }
    }
}
