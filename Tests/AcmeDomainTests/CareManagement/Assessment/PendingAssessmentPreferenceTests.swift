@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingAssessmentPreferenceTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newPendingAssessmentPreference("code-601", label: "label-706")
        #expect(item.status == CareManagement.PendingAssessmentPreferenceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newPendingAssessmentPreference("code-601", label: "label-706")
        try item.moveTo(CareManagement.PendingAssessmentPreferenceStatus.running)
        #expect(item.status == CareManagement.PendingAssessmentPreferenceStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newPendingAssessmentPreference("code-601", label: "label-706")
        item.status = CareManagement.PendingAssessmentPreferenceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingAssessmentPreferenceStatus.new) }
    }
}
