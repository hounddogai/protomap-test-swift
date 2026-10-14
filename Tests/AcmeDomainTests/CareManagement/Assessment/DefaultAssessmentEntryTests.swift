@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultAssessmentEntryTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newDefaultAssessmentEntry("code-606", name: "name-730")
        #expect(item.status == CareManagement.DefaultAssessmentEntryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newDefaultAssessmentEntry("code-606", name: "name-730")
        try item.moveTo(CareManagement.DefaultAssessmentEntryStatus.approved)
        #expect(item.status == CareManagement.DefaultAssessmentEntryStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newDefaultAssessmentEntry("code-606", name: "name-730")
        item.status = CareManagement.DefaultAssessmentEntryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultAssessmentEntryStatus.proposed) }
    }
}
