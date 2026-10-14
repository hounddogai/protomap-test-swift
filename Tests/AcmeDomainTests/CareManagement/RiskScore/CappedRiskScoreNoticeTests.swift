@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreNoticeTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newCappedRiskScoreNotice("code-77", label: "label-952")
        #expect(item.status == CareManagement.CappedRiskScoreNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newCappedRiskScoreNotice("code-77", label: "label-952")
        try item.moveTo(CareManagement.CappedRiskScoreNoticeStatus.expired)
        #expect(item.status == CareManagement.CappedRiskScoreNoticeStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newCappedRiskScoreNotice("code-77", label: "label-952")
        item.status = CareManagement.CappedRiskScoreNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedRiskScoreNoticeStatus.requested) }
    }
}
