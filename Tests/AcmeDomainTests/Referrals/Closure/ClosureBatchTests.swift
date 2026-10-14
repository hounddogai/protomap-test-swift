@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBatchTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newClosureBatch("code-858", label: "label-812")
        #expect(item.status == Referrals.ClosureBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newClosureBatch("code-858", label: "label-812")
        try item.moveTo(Referrals.ClosureBatchStatus.active)
        #expect(item.status == Referrals.ClosureBatchStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newClosureBatch("code-858", label: "label-812")
        item.status = Referrals.ClosureBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureBatchStatus.draft) }
    }
}
