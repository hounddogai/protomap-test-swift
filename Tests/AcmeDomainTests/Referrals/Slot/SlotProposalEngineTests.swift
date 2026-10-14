@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSlotProposalEngine(Kit.Flags.newRegistry())
        let item = Referrals.newSlotProposal("code-56", title: "title-598")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
