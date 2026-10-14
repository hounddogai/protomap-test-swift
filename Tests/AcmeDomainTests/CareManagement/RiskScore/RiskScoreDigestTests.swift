@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreDigestTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newRiskScoreDigest("code-160", label: "label-516")
        #expect(item.status == CareManagement.RiskScoreDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newRiskScoreDigest("code-160", label: "label-516")
        try item.moveTo(CareManagement.RiskScoreDigestStatus.published)
        #expect(item.status == CareManagement.RiskScoreDigestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newRiskScoreDigest("code-160", label: "label-516")
        item.status = CareManagement.RiskScoreDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreDigestStatus.created) }
    }
}
