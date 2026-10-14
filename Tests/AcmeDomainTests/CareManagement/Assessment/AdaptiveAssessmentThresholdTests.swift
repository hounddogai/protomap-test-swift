@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveAssessmentThresholdTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newAdaptiveAssessmentThreshold("code-985", title: "title-955")
        #expect(item.status == CareManagement.AdaptiveAssessmentThresholdStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newAdaptiveAssessmentThreshold("code-985", title: "title-955")
        try item.moveTo(CareManagement.AdaptiveAssessmentThresholdStatus.approved)
        #expect(item.status == CareManagement.AdaptiveAssessmentThresholdStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newAdaptiveAssessmentThreshold("code-985", title: "title-955")
        item.status = CareManagement.AdaptiveAssessmentThresholdStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveAssessmentThresholdStatus.proposed) }
    }
}
