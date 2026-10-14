@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanAdjustmentTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newPrimaryDischargePlanAdjustment("code-205", title: "title-474")
        #expect(item.status == BedManagement.PrimaryDischargePlanAdjustmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newPrimaryDischargePlanAdjustment("code-205", title: "title-474")
        try item.moveTo(BedManagement.PrimaryDischargePlanAdjustmentStatus.active)
        #expect(item.status == BedManagement.PrimaryDischargePlanAdjustmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newPrimaryDischargePlanAdjustment("code-205", title: "title-474")
        item.status = BedManagement.PrimaryDischargePlanAdjustmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryDischargePlanAdjustmentStatus.draft) }
    }
}
