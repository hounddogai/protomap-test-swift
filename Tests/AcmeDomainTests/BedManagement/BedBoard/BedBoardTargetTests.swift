@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardTargetTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newBedBoardTarget("code-478", label: "label-341")
        #expect(item.status == BedManagement.BedBoardTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newBedBoardTarget("code-478", label: "label-341")
        try item.moveTo(BedManagement.BedBoardTargetStatus.approved)
        #expect(item.status == BedManagement.BedBoardTargetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newBedBoardTarget("code-478", label: "label-341")
        item.status = BedManagement.BedBoardTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardTargetStatus.proposed) }
    }
}
