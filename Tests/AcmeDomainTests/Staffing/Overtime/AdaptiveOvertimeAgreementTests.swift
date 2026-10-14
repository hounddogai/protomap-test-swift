@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveOvertimeAgreementTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newAdaptiveOvertimeAgreement("code-37", label: "label-542")
        #expect(item.status == Staffing.AdaptiveOvertimeAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Staffing.newAdaptiveOvertimeAgreement("code-37", label: "label-542")
        try item.moveTo(Staffing.AdaptiveOvertimeAgreementStatus.expired)
        #expect(item.status == Staffing.AdaptiveOvertimeAgreementStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newAdaptiveOvertimeAgreement("code-37", label: "label-542")
        item.status = Staffing.AdaptiveOvertimeAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveOvertimeAgreementStatus.requested) }
    }
}
