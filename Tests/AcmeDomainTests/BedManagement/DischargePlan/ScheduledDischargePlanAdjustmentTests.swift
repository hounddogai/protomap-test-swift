@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanAdjustmentTests {
    @Test func startsInCreated() throws {
        let item = BedManagement.newScheduledDischargePlanAdjustment("code-473", title: "title-957")
        #expect(item.status == BedManagement.ScheduledDischargePlanAdjustmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = BedManagement.newScheduledDischargePlanAdjustment("code-473", title: "title-957")
        try item.moveTo(BedManagement.ScheduledDischargePlanAdjustmentStatus.validated)
        #expect(item.status == BedManagement.ScheduledDischargePlanAdjustmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = BedManagement.newScheduledDischargePlanAdjustment("code-473", title: "title-957")
        item.status = BedManagement.ScheduledDischargePlanAdjustmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledDischargePlanAdjustmentStatus.created) }
    }
}
