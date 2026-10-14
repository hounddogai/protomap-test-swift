@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultTieredFollowUpTierEngine(Kit.Flags.newRegistry())
        let item = Referrals.newTieredFollowUpTier("code-952", name: "name-378")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
