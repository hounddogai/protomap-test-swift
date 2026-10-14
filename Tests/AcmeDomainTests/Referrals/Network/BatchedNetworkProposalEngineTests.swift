@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsBatchedNetworkProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultBatchedNetworkProposalEngine(Kit.Flags.newRegistry())
        let item = Referrals.newBatchedNetworkProposal("code-585", name: "name-704")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
