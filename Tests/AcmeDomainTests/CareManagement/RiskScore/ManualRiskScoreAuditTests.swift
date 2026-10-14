@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualRiskScoreAuditTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newManualRiskScoreAudit("code-429", title: "title-12")
        #expect(item.status == CareManagement.ManualRiskScoreAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newManualRiskScoreAudit("code-429", title: "title-12")
        try item.moveTo(CareManagement.ManualRiskScoreAuditStatus.published)
        #expect(item.status == CareManagement.ManualRiskScoreAuditStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newManualRiskScoreAudit("code-429", title: "title-12")
        item.status = CareManagement.ManualRiskScoreAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualRiskScoreAuditStatus.created) }
    }
}
