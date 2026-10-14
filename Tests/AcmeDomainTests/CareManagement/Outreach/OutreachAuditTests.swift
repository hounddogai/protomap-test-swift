@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAuditTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newOutreachAudit("code-861", name: "name-43")
        #expect(item.status == CareManagement.OutreachAuditStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newOutreachAudit("code-861", name: "name-43")
        try item.moveTo(CareManagement.OutreachAuditStatus.inReview)
        #expect(item.status == CareManagement.OutreachAuditStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newOutreachAudit("code-861", name: "name-43")
        item.status = CareManagement.OutreachAuditStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachAuditStatus.`open`) }
    }
}
