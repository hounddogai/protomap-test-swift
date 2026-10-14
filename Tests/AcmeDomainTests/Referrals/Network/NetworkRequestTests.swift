@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRequestTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newNetworkRequest("code-478", label: "label-276")
        #expect(item.status == Referrals.NetworkRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newNetworkRequest("code-478", label: "label-276")
        try item.moveTo(Referrals.NetworkRequestStatus.active)
        #expect(item.status == Referrals.NetworkRequestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newNetworkRequest("code-478", label: "label-276")
        item.status = Referrals.NetworkRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkRequestStatus.draft) }
    }
}
