@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedAssessmentBaselineTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCappedAssessmentBaseline("code-497", label: "label-123")
        #expect(item.status == CareManagement.CappedAssessmentBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newCappedAssessmentBaseline("code-497", label: "label-123")
        try item.moveTo(CareManagement.CappedAssessmentBaselineStatus.resolved)
        #expect(item.status == CareManagement.CappedAssessmentBaselineStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCappedAssessmentBaseline("code-497", label: "label-123")
        item.status = CareManagement.CappedAssessmentBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedAssessmentBaselineStatus.`open`) }
    }
}
