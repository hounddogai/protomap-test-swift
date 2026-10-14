@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualRiskScoreGroupTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newManualRiskScoreGroup("code-881", label: "label-293")
        #expect(item.status == CareManagement.ManualRiskScoreGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = CareManagement.newManualRiskScoreGroup("code-881", label: "label-293")
        try item.moveTo(CareManagement.ManualRiskScoreGroupStatus.rejected)
        #expect(item.status == CareManagement.ManualRiskScoreGroupStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newManualRiskScoreGroup("code-881", label: "label-293")
        item.status = CareManagement.ManualRiskScoreGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualRiskScoreGroupStatus.proposed) }
    }
}
