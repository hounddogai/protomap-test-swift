@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveShiftNoticeTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newAdaptiveShiftNotice("code-810", title: "title-996")
        #expect(item.status == Staffing.AdaptiveShiftNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newAdaptiveShiftNotice("code-810", title: "title-996")
        try item.moveTo(Staffing.AdaptiveShiftNoticeStatus.expired)
        #expect(item.status == Staffing.AdaptiveShiftNoticeStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newAdaptiveShiftNotice("code-810", title: "title-996")
        item.status = Staffing.AdaptiveShiftNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveShiftNoticeStatus.requested) }
    }
}
