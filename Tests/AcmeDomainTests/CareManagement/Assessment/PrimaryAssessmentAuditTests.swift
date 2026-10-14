@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryAssessmentAuditTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newPrimaryAssessmentAudit("code-845", name: "name-473")
        #expect(item.status == CareManagement.PrimaryAssessmentAuditStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newPrimaryAssessmentAudit("code-845", name: "name-473")
        try item.moveTo(CareManagement.PrimaryAssessmentAuditStatus.granted)
        #expect(item.status == CareManagement.PrimaryAssessmentAuditStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newPrimaryAssessmentAudit("code-845", name: "name-473")
        item.status = CareManagement.PrimaryAssessmentAuditStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryAssessmentAuditStatus.requested) }
    }
}
