@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictOvertimeAgreementTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newStrictOvertimeAgreement("code-814", title: "title-98")
        #expect(item.status == Staffing.StrictOvertimeAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newStrictOvertimeAgreement("code-814", title: "title-98")
        try item.moveTo(Staffing.StrictOvertimeAgreementStatus.granted)
        #expect(item.status == Staffing.StrictOvertimeAgreementStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newStrictOvertimeAgreement("code-814", title: "title-98")
        item.status = Staffing.StrictOvertimeAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.StrictOvertimeAgreementStatus.requested) }
    }
}
