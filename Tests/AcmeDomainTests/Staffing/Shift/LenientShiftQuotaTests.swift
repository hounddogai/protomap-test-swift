@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientShiftQuotaTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newLenientShiftQuota("code-853", label: "label-183")
        #expect(item.status == Staffing.LenientShiftQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newLenientShiftQuota("code-853", label: "label-183")
        try item.moveTo(Staffing.LenientShiftQuotaStatus.suspended)
        #expect(item.status == Staffing.LenientShiftQuotaStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newLenientShiftQuota("code-853", label: "label-183")
        item.status = Staffing.LenientShiftQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientShiftQuotaStatus.draft) }
    }
}
