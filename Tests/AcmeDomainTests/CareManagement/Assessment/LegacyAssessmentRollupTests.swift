@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyAssessmentRollupTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newLegacyAssessmentRollup("code-130", label: "label-409")
        #expect(item.status == CareManagement.LegacyAssessmentRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = CareManagement.newLegacyAssessmentRollup("code-130", label: "label-409")
        try item.moveTo(CareManagement.LegacyAssessmentRollupStatus.running)
        #expect(item.status == CareManagement.LegacyAssessmentRollupStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newLegacyAssessmentRollup("code-130", label: "label-409")
        item.status = CareManagement.LegacyAssessmentRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyAssessmentRollupStatus.new) }
    }
}
