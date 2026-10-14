@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentLedgerTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newAssessmentLedger("code-870", name: "name-176")
        #expect(item.status == CareManagement.AssessmentLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newAssessmentLedger("code-870", name: "name-176")
        try item.moveTo(CareManagement.AssessmentLedgerStatus.published)
        #expect(item.status == CareManagement.AssessmentLedgerStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newAssessmentLedger("code-870", name: "name-176")
        item.status = CareManagement.AssessmentLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentLedgerStatus.created) }
    }
}
