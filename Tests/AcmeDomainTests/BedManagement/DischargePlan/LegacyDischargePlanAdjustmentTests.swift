@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyDischargePlanAdjustmentTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newLegacyDischargePlanAdjustment("code-414", label: "label-787")
        #expect(item.status == BedManagement.LegacyDischargePlanAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newLegacyDischargePlanAdjustment("code-414", label: "label-787")
        try item.moveTo(BedManagement.LegacyDischargePlanAdjustmentStatus.running)
        #expect(item.status == BedManagement.LegacyDischargePlanAdjustmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newLegacyDischargePlanAdjustment("code-414", label: "label-787")
        item.status = BedManagement.LegacyDischargePlanAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyDischargePlanAdjustmentStatus.new) }
    }
}
