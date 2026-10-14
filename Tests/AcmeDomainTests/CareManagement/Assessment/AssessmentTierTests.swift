@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentTierTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newAssessmentTier("code-229", name: "name-563")
        #expect(item.status == CareManagement.AssessmentTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newAssessmentTier("code-229", name: "name-563")
        try item.moveTo(CareManagement.AssessmentTierStatus.queued)
        #expect(item.status == CareManagement.AssessmentTierStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newAssessmentTier("code-229", name: "name-563")
        item.status = CareManagement.AssessmentTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentTierStatus.new) }
    }
}
