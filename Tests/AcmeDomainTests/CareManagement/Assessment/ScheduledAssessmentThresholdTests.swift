@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledAssessmentThresholdTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newScheduledAssessmentThreshold("code-237", title: "title-697")
        #expect(item.status == CareManagement.ScheduledAssessmentThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = CareManagement.newScheduledAssessmentThreshold("code-237", title: "title-697")
        try item.moveTo(CareManagement.ScheduledAssessmentThresholdStatus.failed)
        #expect(item.status == CareManagement.ScheduledAssessmentThresholdStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newScheduledAssessmentThreshold("code-237", title: "title-697")
        item.status = CareManagement.ScheduledAssessmentThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledAssessmentThresholdStatus.new) }
    }
}
