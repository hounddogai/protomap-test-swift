@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualTransferGroupTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newManualTransferGroup("code-291", label: "label-489")
        #expect(item.status == BedManagement.ManualTransferGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newManualTransferGroup("code-291", label: "label-489")
        try item.moveTo(BedManagement.ManualTransferGroupStatus.approved)
        #expect(item.status == BedManagement.ManualTransferGroupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newManualTransferGroup("code-291", label: "label-489")
        item.status = BedManagement.ManualTransferGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualTransferGroupStatus.proposed) }
    }
}
