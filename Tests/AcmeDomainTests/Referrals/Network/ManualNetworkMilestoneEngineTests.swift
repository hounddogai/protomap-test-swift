@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualNetworkMilestoneEngine(Kit.Flags.newRegistry())
        let item = Referrals.newManualNetworkMilestone("code-466", title: "title-807")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
