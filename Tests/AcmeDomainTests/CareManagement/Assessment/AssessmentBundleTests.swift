@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBundleTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newAssessmentBundle("code-669", label: "label-833")
        #expect(item.status == CareManagement.AssessmentBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newAssessmentBundle("code-669", label: "label-833")
        try item.moveTo(CareManagement.AssessmentBundleStatus.queued)
        #expect(item.status == CareManagement.AssessmentBundleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newAssessmentBundle("code-669", label: "label-833")
        item.status = CareManagement.AssessmentBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentBundleStatus.new) }
    }
}
