@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementGlobalTransferAuditTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newGlobalTransferAudit("code-667", name: "name-33")
        #expect(item.status == BedManagement.GlobalTransferAuditStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = BedManagement.newGlobalTransferAudit("code-667", name: "name-33")
        try item.moveTo(BedManagement.GlobalTransferAuditStatus.withdrawn)
        #expect(item.status == BedManagement.GlobalTransferAuditStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newGlobalTransferAudit("code-667", name: "name-33")
        item.status = BedManagement.GlobalTransferAuditStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.GlobalTransferAuditStatus.proposed) }
    }
}
