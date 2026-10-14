@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredCareGapAuditTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newTieredCareGapAudit("code-548", title: "title-639")
        #expect(item.status == CareManagement.TieredCareGapAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newTieredCareGapAudit("code-548", title: "title-639")
        try item.moveTo(CareManagement.TieredCareGapAuditStatus.revoked)
        #expect(item.status == CareManagement.TieredCareGapAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newTieredCareGapAudit("code-548", title: "title-639")
        item.status = CareManagement.TieredCareGapAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredCareGapAuditStatus.requested) }
    }
}
