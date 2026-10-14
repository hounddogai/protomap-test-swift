@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingShiftNoticeTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newRollingShiftNotice("code-867", label: "label-426")
        #expect(item.status == Staffing.RollingShiftNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newRollingShiftNotice("code-867", label: "label-426")
        try item.moveTo(Staffing.RollingShiftNoticeStatus.published)
        #expect(item.status == Staffing.RollingShiftNoticeStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newRollingShiftNotice("code-867", label: "label-426")
        item.status = Staffing.RollingShiftNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingShiftNoticeStatus.created) }
    }
}
