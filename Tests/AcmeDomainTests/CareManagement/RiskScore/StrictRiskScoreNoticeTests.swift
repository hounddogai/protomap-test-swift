@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictRiskScoreNoticeTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newStrictRiskScoreNotice("code-839", name: "name-423")
        #expect(item.status == CareManagement.StrictRiskScoreNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newStrictRiskScoreNotice("code-839", name: "name-423")
        try item.moveTo(CareManagement.StrictRiskScoreNoticeStatus.failed)
        #expect(item.status == CareManagement.StrictRiskScoreNoticeStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newStrictRiskScoreNotice("code-839", name: "name-423")
        item.status = CareManagement.StrictRiskScoreNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.StrictRiskScoreNoticeStatus.new) }
    }
}
