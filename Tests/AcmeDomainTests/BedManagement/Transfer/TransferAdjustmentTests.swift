@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newTransferAdjustment("code-34", title: "title-676")
        #expect(item.status == BedManagement.TransferAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newTransferAdjustment("code-34", title: "title-676")
        try item.moveTo(BedManagement.TransferAdjustmentStatus.approved)
        #expect(item.status == BedManagement.TransferAdjustmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newTransferAdjustment("code-34", title: "title-676")
        item.status = BedManagement.TransferAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferAdjustmentStatus.proposed) }
    }
}
