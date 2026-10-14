@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultOutreachAuditTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newDefaultOutreachAudit("code-589", title: "title-818")
        #expect(item.status == CareManagement.DefaultOutreachAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newDefaultOutreachAudit("code-589", title: "title-818")
        try item.moveTo(CareManagement.DefaultOutreachAuditStatus.revoked)
        #expect(item.status == CareManagement.DefaultOutreachAuditStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newDefaultOutreachAudit("code-589", title: "title-818")
        item.status = CareManagement.DefaultOutreachAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultOutreachAuditStatus.requested) }
    }
}
