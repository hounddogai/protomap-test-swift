@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotExceptionTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newDefaultSlotException("code-510", name: "name-363")
        #expect(item.status == Referrals.DefaultSlotExceptionStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newDefaultSlotException("code-510", name: "name-363")
        try item.moveTo(Referrals.DefaultSlotExceptionStatus.granted)
        #expect(item.status == Referrals.DefaultSlotExceptionStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newDefaultSlotException("code-510", name: "name-363")
        item.status = Referrals.DefaultSlotExceptionStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultSlotExceptionStatus.requested) }
    }
}
