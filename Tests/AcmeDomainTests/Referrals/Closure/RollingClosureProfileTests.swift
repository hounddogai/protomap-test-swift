@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProfileTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newRollingClosureProfile("code-504", title: "title-949")
        #expect(item.status == Referrals.RollingClosureProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newRollingClosureProfile("code-504", title: "title-949")
        try item.moveTo(Referrals.RollingClosureProfileStatus.warming)
        #expect(item.status == Referrals.RollingClosureProfileStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newRollingClosureProfile("code-504", title: "title-949")
        item.status = Referrals.RollingClosureProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingClosureProfileStatus.idle) }
    }
}
