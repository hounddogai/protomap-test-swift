@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolNoticeTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newFloatPoolNotice("code-434", title: "title-501")
        #expect(item.status == Staffing.FloatPoolNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newFloatPoolNotice("code-434", title: "title-501")
        try item.moveTo(Staffing.FloatPoolNoticeStatus.active)
        #expect(item.status == Staffing.FloatPoolNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newFloatPoolNotice("code-434", title: "title-501")
        item.status = Staffing.FloatPoolNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolNoticeStatus.draft) }
    }
}
