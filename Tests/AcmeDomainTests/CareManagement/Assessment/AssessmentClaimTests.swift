@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentClaimTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAssessmentClaim("code-800", label: "label-717")
        #expect(item.status == CareManagement.AssessmentClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newAssessmentClaim("code-800", label: "label-717")
        try item.moveTo(CareManagement.AssessmentClaimStatus.rejected)
        #expect(item.status == CareManagement.AssessmentClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAssessmentClaim("code-800", label: "label-717")
        item.status = CareManagement.AssessmentClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentClaimStatus.proposed) }
    }
}
