@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreAgreementTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRiskScoreAgreement("code-321", name: "name-783")
        #expect(item.status == CareManagement.RiskScoreAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newRiskScoreAgreement("code-321", name: "name-783")
        try item.moveTo(CareManagement.RiskScoreAgreementStatus.revoked)
        #expect(item.status == CareManagement.RiskScoreAgreementStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRiskScoreAgreement("code-321", name: "name-783")
        item.status = CareManagement.RiskScoreAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreAgreementStatus.requested) }
    }
}
