@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalReferralMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSeasonalReferralMappingEngine(Kit.Flags.newRegistry())
        let item = Referrals.newSeasonalReferralMapping("code-526", label: "label-297")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
