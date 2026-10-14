@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanAgreementTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newAcuityPlanAgreement("code-748", label: "label-564")
        #expect(item.status == Staffing.AcuityPlanAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newAcuityPlanAgreement("code-748", label: "label-564")
        try item.moveTo(Staffing.AcuityPlanAgreementStatus.inReview)
        #expect(item.status == Staffing.AcuityPlanAgreementStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newAcuityPlanAgreement("code-748", label: "label-564")
        item.status = Staffing.AcuityPlanAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanAgreementStatus.`open`) }
    }
}
