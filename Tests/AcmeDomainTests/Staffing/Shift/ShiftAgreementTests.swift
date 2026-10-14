@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAgreementTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newShiftAgreement("code-549", name: "name-4")
        #expect(item.status == Staffing.ShiftAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newShiftAgreement("code-549", name: "name-4")
        try item.moveTo(Staffing.ShiftAgreementStatus.granted)
        #expect(item.status == Staffing.ShiftAgreementStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newShiftAgreement("code-549", name: "name-4")
        item.status = Staffing.ShiftAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftAgreementStatus.requested) }
    }
}
