@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentNoticeTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRegionalAssessmentNotice("code-189", label: "label-231")
        #expect(item.status == CareManagement.RegionalAssessmentNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newRegionalAssessmentNotice("code-189", label: "label-231")
        try item.moveTo(CareManagement.RegionalAssessmentNoticeStatus.inProgress)
        #expect(item.status == CareManagement.RegionalAssessmentNoticeStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRegionalAssessmentNotice("code-189", label: "label-231")
        item.status = CareManagement.RegionalAssessmentNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalAssessmentNoticeStatus.planned) }
    }
}
