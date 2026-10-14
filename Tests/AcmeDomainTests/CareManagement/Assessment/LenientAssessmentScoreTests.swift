@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientAssessmentScoreTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newLenientAssessmentScore("code-549", name: "name-370")
        #expect(item.status == CareManagement.LenientAssessmentScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newLenientAssessmentScore("code-549", name: "name-370")
        try item.moveTo(CareManagement.LenientAssessmentScoreStatus.active)
        #expect(item.status == CareManagement.LenientAssessmentScoreStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newLenientAssessmentScore("code-549", name: "name-370")
        item.status = CareManagement.LenientAssessmentScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientAssessmentScoreStatus.draft) }
    }
}
