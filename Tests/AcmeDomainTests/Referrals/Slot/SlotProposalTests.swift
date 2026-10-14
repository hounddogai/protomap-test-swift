@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotProposalTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSlotProposal("code-56", title: "title-598")
        #expect(item.status == Referrals.SlotProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newSlotProposal("code-56", title: "title-598")
        try item.moveTo(Referrals.SlotProposalStatus.resolved)
        #expect(item.status == Referrals.SlotProposalStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSlotProposal("code-56", title: "title-598")
        item.status = Referrals.SlotProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotProposalStatus.`open`) }
    }
}
