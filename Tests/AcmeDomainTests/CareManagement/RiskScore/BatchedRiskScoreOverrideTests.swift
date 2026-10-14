@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedRiskScoreOverrideTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newBatchedRiskScoreOverride("code-463", label: "label-515")
        #expect(item.status == CareManagement.BatchedRiskScoreOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newBatchedRiskScoreOverride("code-463", label: "label-515")
        try item.moveTo(CareManagement.BatchedRiskScoreOverrideStatus.expired)
        #expect(item.status == CareManagement.BatchedRiskScoreOverrideStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newBatchedRiskScoreOverride("code-463", label: "label-515")
        item.status = CareManagement.BatchedRiskScoreOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedRiskScoreOverrideStatus.requested) }
    }
}
