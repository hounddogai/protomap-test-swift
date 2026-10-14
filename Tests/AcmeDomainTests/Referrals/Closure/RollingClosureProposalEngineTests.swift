@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingClosureProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRollingClosureProposalEngine()
        let item = Referrals.newRollingClosureProposal("code-94", label: "label-599")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
