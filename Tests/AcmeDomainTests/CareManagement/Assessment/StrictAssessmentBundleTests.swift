@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentBundleTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newStrictAssessmentBundle("code-122", label: "label-246")
        #expect(item.status == CareManagement.StrictAssessmentBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newStrictAssessmentBundle("code-122", label: "label-246")
        try item.moveTo(CareManagement.StrictAssessmentBundleStatus.scheduled)
        #expect(item.status == CareManagement.StrictAssessmentBundleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newStrictAssessmentBundle("code-122", label: "label-246")
        item.status = CareManagement.StrictAssessmentBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.StrictAssessmentBundleStatus.planned) }
    }
}
