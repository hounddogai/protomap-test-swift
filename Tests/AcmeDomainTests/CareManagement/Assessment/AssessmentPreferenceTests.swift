@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentPreferenceTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newAssessmentPreference("code-345", title: "title-318")
        #expect(item.status == CareManagement.AssessmentPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newAssessmentPreference("code-345", title: "title-318")
        try item.moveTo(CareManagement.AssessmentPreferenceStatus.granted)
        #expect(item.status == CareManagement.AssessmentPreferenceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newAssessmentPreference("code-345", title: "title-318")
        item.status = CareManagement.AssessmentPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentPreferenceStatus.requested) }
    }
}
