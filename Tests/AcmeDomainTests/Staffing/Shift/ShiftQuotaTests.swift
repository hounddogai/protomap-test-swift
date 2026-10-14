@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftQuotaTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newShiftQuota("code-632", name: "name-274")
        #expect(item.status == Staffing.ShiftQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newShiftQuota("code-632", name: "name-274")
        try item.moveTo(Staffing.ShiftQuotaStatus.published)
        #expect(item.status == Staffing.ShiftQuotaStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newShiftQuota("code-632", name: "name-274")
        item.status = Staffing.ShiftQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftQuotaStatus.created) }
    }
}
