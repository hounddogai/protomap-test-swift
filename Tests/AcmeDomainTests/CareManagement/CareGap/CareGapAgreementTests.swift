@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapAgreementTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newCareGapAgreement("code-328", title: "title-878")
        #expect(item.status == CareManagement.CareGapAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newCareGapAgreement("code-328", title: "title-878")
        try item.moveTo(CareManagement.CareGapAgreementStatus.revoked)
        #expect(item.status == CareManagement.CareGapAgreementStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newCareGapAgreement("code-328", title: "title-878")
        item.status = CareManagement.CareGapAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapAgreementStatus.requested) }
    }
}
