@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureCycleTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newClosureCycle("code-383", label: "label-430")
        #expect(item.status == Referrals.ClosureCycleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newClosureCycle("code-383", label: "label-430")
        try item.moveTo(Referrals.ClosureCycleStatus.warming)
        #expect(item.status == Referrals.ClosureCycleStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newClosureCycle("code-383", label: "label-430")
        item.status = Referrals.ClosureCycleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureCycleStatus.idle) }
    }
}
