@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedCareGapBundleTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newBatchedCareGapBundle("code-473", name: "name-849")
        #expect(item.status == CareManagement.BatchedCareGapBundleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newBatchedCareGapBundle("code-473", name: "name-849")
        try item.moveTo(CareManagement.BatchedCareGapBundleStatus.revoked)
        #expect(item.status == CareManagement.BatchedCareGapBundleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newBatchedCareGapBundle("code-473", name: "name-849")
        item.status = CareManagement.BatchedCareGapBundleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.BatchedCareGapBundleStatus.requested) }
    }
}
