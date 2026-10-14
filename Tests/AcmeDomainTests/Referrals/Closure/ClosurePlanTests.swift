@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePlanTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newClosurePlan("code-152", name: "name-875")
        #expect(item.status == Referrals.ClosurePlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newClosurePlan("code-152", name: "name-875")
        try item.moveTo(Referrals.ClosurePlanStatus.granted)
        #expect(item.status == Referrals.ClosurePlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newClosurePlan("code-152", name: "name-875")
        item.status = Referrals.ClosurePlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosurePlanStatus.requested) }
    }
}
