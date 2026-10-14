@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedReferralAssignmentTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newBatchedReferralAssignment("code-934", label: "label-668")
        #expect(item.status == Referrals.BatchedReferralAssignmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newBatchedReferralAssignment("code-934", label: "label-668")
        try item.moveTo(Referrals.BatchedReferralAssignmentStatus.granted)
        #expect(item.status == Referrals.BatchedReferralAssignmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newBatchedReferralAssignment("code-934", label: "label-668")
        item.status = Referrals.BatchedReferralAssignmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.BatchedReferralAssignmentStatus.requested) }
    }
}
