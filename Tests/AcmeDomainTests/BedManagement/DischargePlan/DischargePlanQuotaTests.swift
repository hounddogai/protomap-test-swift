@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanQuotaTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newDischargePlanQuota("code-966", label: "label-539")
        #expect(item.status == BedManagement.DischargePlanQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newDischargePlanQuota("code-966", label: "label-539")
        try item.moveTo(BedManagement.DischargePlanQuotaStatus.active)
        #expect(item.status == BedManagement.DischargePlanQuotaStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newDischargePlanQuota("code-966", label: "label-539")
        item.status = BedManagement.DischargePlanQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanQuotaStatus.draft) }
    }
}
