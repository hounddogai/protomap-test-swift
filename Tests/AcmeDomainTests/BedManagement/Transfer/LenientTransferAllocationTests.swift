@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientTransferAllocationTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newLenientTransferAllocation("code-297", label: "label-30")
        #expect(item.status == BedManagement.LenientTransferAllocationStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newLenientTransferAllocation("code-297", label: "label-30")
        try item.moveTo(BedManagement.LenientTransferAllocationStatus.approved)
        #expect(item.status == BedManagement.LenientTransferAllocationStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newLenientTransferAllocation("code-297", label: "label-30")
        item.status = BedManagement.LenientTransferAllocationStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LenientTransferAllocationStatus.proposed) }
    }
}
