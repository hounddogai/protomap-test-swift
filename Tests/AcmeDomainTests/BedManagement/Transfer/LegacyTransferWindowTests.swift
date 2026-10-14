@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyTransferWindowTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newLegacyTransferWindow("code-769", name: "name-391")
        #expect(item.status == BedManagement.LegacyTransferWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newLegacyTransferWindow("code-769", name: "name-391")
        try item.moveTo(BedManagement.LegacyTransferWindowStatus.approved)
        #expect(item.status == BedManagement.LegacyTransferWindowStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newLegacyTransferWindow("code-769", name: "name-391")
        item.status = BedManagement.LegacyTransferWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyTransferWindowStatus.proposed) }
    }
}
