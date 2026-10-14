@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScorePreferenceTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newBatchedRiskScorePreference("code-159", name: "name-163")
        #expect(item.status == CareManagement.BatchedRiskScorePreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newBatchedRiskScorePreference("code-159", name: "name-163")
        try item.moveTo(CareManagement.BatchedRiskScorePreferenceStatus.scheduled)
        #expect(item.status == CareManagement.BatchedRiskScorePreferenceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newBatchedRiskScorePreference("code-159", name: "name-163")
        item.status = CareManagement.BatchedRiskScorePreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedRiskScorePreferenceStatus.planned) }
    }
}
