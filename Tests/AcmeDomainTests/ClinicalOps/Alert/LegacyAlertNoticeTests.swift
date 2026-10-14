@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyAlertNoticeTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newLegacyAlertNotice("code-108", name: "name-702")
        #expect(item.status == ClinicalOps.LegacyAlertNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newLegacyAlertNotice("code-108", name: "name-702")
        try item.moveTo(ClinicalOps.LegacyAlertNoticeStatus.revoked)
        #expect(item.status == ClinicalOps.LegacyAlertNoticeStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newLegacyAlertNotice("code-108", name: "name-702")
        item.status = ClinicalOps.LegacyAlertNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyAlertNoticeStatus.requested) }
    }
}
