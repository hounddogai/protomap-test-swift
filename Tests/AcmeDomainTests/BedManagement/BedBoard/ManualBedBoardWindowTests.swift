@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualBedBoardWindowTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newManualBedBoardWindow("code-349", label: "label-237")
        #expect(item.status == BedManagement.ManualBedBoardWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newManualBedBoardWindow("code-349", label: "label-237")
        try item.moveTo(BedManagement.ManualBedBoardWindowStatus.rejected)
        #expect(item.status == BedManagement.ManualBedBoardWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newManualBedBoardWindow("code-349", label: "label-237")
        item.status = BedManagement.ManualBedBoardWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualBedBoardWindowStatus.proposed) }
    }
}
