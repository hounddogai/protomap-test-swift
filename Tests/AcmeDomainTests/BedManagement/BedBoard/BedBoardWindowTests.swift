@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardWindowTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newBedBoardWindow("code-803", title: "title-348")
        #expect(item.status == BedManagement.BedBoardWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newBedBoardWindow("code-803", title: "title-348")
        try item.moveTo(BedManagement.BedBoardWindowStatus.rejected)
        #expect(item.status == BedManagement.BedBoardWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newBedBoardWindow("code-803", title: "title-348")
        item.status = BedManagement.BedBoardWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardWindowStatus.proposed) }
    }
}
