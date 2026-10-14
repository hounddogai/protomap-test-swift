@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreGroupTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newRiskScoreGroup("code-54", title: "title-274")
        #expect(item.status == CareManagement.RiskScoreGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newRiskScoreGroup("code-54", title: "title-274")
        try item.moveTo(CareManagement.RiskScoreGroupStatus.failed)
        #expect(item.status == CareManagement.RiskScoreGroupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newRiskScoreGroup("code-54", title: "title-274")
        item.status = CareManagement.RiskScoreGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreGroupStatus.new) }
    }
}
