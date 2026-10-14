@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledTransferAdjustmentTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newScheduledTransferAdjustment("code-800", label: "label-761")
        #expect(item.status == BedManagement.ScheduledTransferAdjustmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = BedManagement.newScheduledTransferAdjustment("code-800", label: "label-761")
        try item.moveTo(BedManagement.ScheduledTransferAdjustmentStatus.withdrawn)
        #expect(item.status == BedManagement.ScheduledTransferAdjustmentStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newScheduledTransferAdjustment("code-800", label: "label-761")
        item.status = BedManagement.ScheduledTransferAdjustmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledTransferAdjustmentStatus.proposed) }
    }
}
