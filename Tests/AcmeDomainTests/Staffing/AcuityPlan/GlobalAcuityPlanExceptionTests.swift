@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanExceptionTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newGlobalAcuityPlanException("code-267", title: "title-829")
        #expect(item.status == Staffing.GlobalAcuityPlanExceptionStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newGlobalAcuityPlanException("code-267", title: "title-829")
        try item.moveTo(Staffing.GlobalAcuityPlanExceptionStatus.granted)
        #expect(item.status == Staffing.GlobalAcuityPlanExceptionStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newGlobalAcuityPlanException("code-267", title: "title-829")
        item.status = Staffing.GlobalAcuityPlanExceptionStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalAcuityPlanExceptionStatus.requested) }
    }
}
