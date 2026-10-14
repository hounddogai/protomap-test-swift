@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferTargetTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newTransferTarget("code-728", name: "name-853")
        #expect(item.status == BedManagement.TransferTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newTransferTarget("code-728", name: "name-853")
        try item.moveTo(BedManagement.TransferTargetStatus.revoked)
        #expect(item.status == BedManagement.TransferTargetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newTransferTarget("code-728", name: "name-853")
        item.status = BedManagement.TransferTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferTargetStatus.requested) }
    }
}
