@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanNoticeTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newLenientAcuityPlanNotice("code-49", title: "title-464")
        #expect(item.status == Staffing.LenientAcuityPlanNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Staffing.newLenientAcuityPlanNotice("code-49", title: "title-464")
        try item.moveTo(Staffing.LenientAcuityPlanNoticeStatus.retired)
        #expect(item.status == Staffing.LenientAcuityPlanNoticeStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newLenientAcuityPlanNotice("code-49", title: "title-464")
        item.status = Staffing.LenientAcuityPlanNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LenientAcuityPlanNoticeStatus.created) }
    }
}
