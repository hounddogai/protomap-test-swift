@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentEntryTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newStrictAssessmentEntry("code-643", label: "label-14")
        #expect(item.status == CareManagement.StrictAssessmentEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = CareManagement.newStrictAssessmentEntry("code-643", label: "label-14")
        try item.moveTo(CareManagement.StrictAssessmentEntryStatus.cancelled)
        #expect(item.status == CareManagement.StrictAssessmentEntryStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newStrictAssessmentEntry("code-643", label: "label-14")
        item.status = CareManagement.StrictAssessmentEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.StrictAssessmentEntryStatus.planned) }
    }
}
