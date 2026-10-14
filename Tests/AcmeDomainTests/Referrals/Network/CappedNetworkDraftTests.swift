@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedNetworkDraftTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newCappedNetworkDraft("code-932", label: "label-684")
        #expect(item.status == Referrals.CappedNetworkDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newCappedNetworkDraft("code-932", label: "label-684")
        try item.moveTo(Referrals.CappedNetworkDraftStatus.reopened)
        #expect(item.status == Referrals.CappedNetworkDraftStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newCappedNetworkDraft("code-932", label: "label-684")
        item.status = Referrals.CappedNetworkDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedNetworkDraftStatus.`open`) }
    }
}
