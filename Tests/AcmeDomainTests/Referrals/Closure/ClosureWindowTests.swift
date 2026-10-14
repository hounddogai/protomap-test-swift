@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureWindowTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newClosureWindow("code-899", label: "label-527")
        #expect(item.status == Referrals.ClosureWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Referrals.newClosureWindow("code-899", label: "label-527")
        try item.moveTo(Referrals.ClosureWindowStatus.retired)
        #expect(item.status == Referrals.ClosureWindowStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newClosureWindow("code-899", label: "label-527")
        item.status = Referrals.ClosureWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureWindowStatus.created) }
    }
}
