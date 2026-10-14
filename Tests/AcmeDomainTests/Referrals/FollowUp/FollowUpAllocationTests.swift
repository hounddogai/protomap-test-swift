@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAllocationTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newFollowUpAllocation("code-588", label: "label-276")
        #expect(item.status == Referrals.FollowUpAllocationStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newFollowUpAllocation("code-588", label: "label-276")
        try item.moveTo(Referrals.FollowUpAllocationStatus.validated)
        #expect(item.status == Referrals.FollowUpAllocationStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newFollowUpAllocation("code-588", label: "label-276")
        item.status = Referrals.FollowUpAllocationStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpAllocationStatus.created) }
    }
}
