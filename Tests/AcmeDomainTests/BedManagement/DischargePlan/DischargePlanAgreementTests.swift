@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAgreementTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newDischargePlanAgreement("code-948", label: "label-888")
        #expect(item.status == BedManagement.DischargePlanAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newDischargePlanAgreement("code-948", label: "label-888")
        try item.moveTo(BedManagement.DischargePlanAgreementStatus.active)
        #expect(item.status == BedManagement.DischargePlanAgreementStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newDischargePlanAgreement("code-948", label: "label-888")
        item.status = BedManagement.DischargePlanAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanAgreementStatus.draft) }
    }
}
