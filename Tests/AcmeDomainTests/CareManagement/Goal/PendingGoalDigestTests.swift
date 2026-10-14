@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalDigestTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newPendingGoalDigest("code-197", title: "title-320")
        #expect(item.status == CareManagement.PendingGoalDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newPendingGoalDigest("code-197", title: "title-320")
        try item.moveTo(CareManagement.PendingGoalDigestStatus.revoked)
        #expect(item.status == CareManagement.PendingGoalDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newPendingGoalDigest("code-197", title: "title-320")
        item.status = CareManagement.PendingGoalDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingGoalDigestStatus.requested) }
    }
}
