@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapNoticeTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newPendingCareGapNotice("code-86", label: "label-329")
        #expect(item.status == CareManagement.PendingCareGapNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newPendingCareGapNotice("code-86", label: "label-329")
        try item.moveTo(CareManagement.PendingCareGapNoticeStatus.revoked)
        #expect(item.status == CareManagement.PendingCareGapNoticeStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newPendingCareGapNotice("code-86", label: "label-329")
        item.status = CareManagement.PendingCareGapNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingCareGapNoticeStatus.requested) }
    }
}
