@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultAssessmentEstimateTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newDefaultAssessmentEstimate("code-795", title: "title-255")
        #expect(item.status == CareManagement.DefaultAssessmentEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newDefaultAssessmentEstimate("code-795", title: "title-255")
        try item.moveTo(CareManagement.DefaultAssessmentEstimateStatus.active)
        #expect(item.status == CareManagement.DefaultAssessmentEstimateStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newDefaultAssessmentEstimate("code-795", title: "title-255")
        item.status = CareManagement.DefaultAssessmentEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultAssessmentEstimateStatus.draft) }
    }
}
