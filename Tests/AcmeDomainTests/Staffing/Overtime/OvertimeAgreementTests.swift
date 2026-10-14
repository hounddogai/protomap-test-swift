@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAgreementTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newOvertimeAgreement("code-668", title: "title-565")
        #expect(item.status == Staffing.OvertimeAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newOvertimeAgreement("code-668", title: "title-565")
        try item.moveTo(Staffing.OvertimeAgreementStatus.published)
        #expect(item.status == Staffing.OvertimeAgreementStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newOvertimeAgreement("code-668", title: "title-565")
        item.status = Staffing.OvertimeAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeAgreementStatus.created) }
    }
}
