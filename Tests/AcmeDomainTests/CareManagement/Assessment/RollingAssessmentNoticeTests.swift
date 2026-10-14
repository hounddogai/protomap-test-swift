@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingAssessmentNoticeTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newRollingAssessmentNotice("code-419", title: "title-179")
        #expect(item.status == CareManagement.RollingAssessmentNoticeStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = CareManagement.newRollingAssessmentNotice("code-419", title: "title-179")
        try item.moveTo(CareManagement.RollingAssessmentNoticeStatus.retired)
        #expect(item.status == CareManagement.RollingAssessmentNoticeStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newRollingAssessmentNotice("code-419", title: "title-179")
        item.status = CareManagement.RollingAssessmentNoticeStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingAssessmentNoticeStatus.created) }
    }
}
