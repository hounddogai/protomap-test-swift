@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAssignmentTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newTransferAssignment("code-192", label: "label-60")
        #expect(item.status == BedManagement.TransferAssignmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newTransferAssignment("code-192", label: "label-60")
        try item.moveTo(BedManagement.TransferAssignmentStatus.approved)
        #expect(item.status == BedManagement.TransferAssignmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newTransferAssignment("code-192", label: "label-60")
        item.status = BedManagement.TransferAssignmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferAssignmentStatus.proposed) }
    }
}
