@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAuditTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newManualOutreachAudit("code-288", label: "label-377")
        #expect(item.status == CareManagement.ManualOutreachAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newManualOutreachAudit("code-288", label: "label-377")
        try item.moveTo(CareManagement.ManualOutreachAuditStatus.published)
        #expect(item.status == CareManagement.ManualOutreachAuditStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newManualOutreachAudit("code-288", label: "label-377")
        item.status = CareManagement.ManualOutreachAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualOutreachAuditStatus.created) }
    }
}
