@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningDigestTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newBatchedCleaningDigest("code-461", label: "label-705")
        #expect(item.status == BedManagement.BatchedCleaningDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newBatchedCleaningDigest("code-461", label: "label-705")
        try item.moveTo(BedManagement.BatchedCleaningDigestStatus.revoked)
        #expect(item.status == BedManagement.BatchedCleaningDigestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newBatchedCleaningDigest("code-461", label: "label-705")
        item.status = BedManagement.BatchedCleaningDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BatchedCleaningDigestStatus.requested) }
    }
}
