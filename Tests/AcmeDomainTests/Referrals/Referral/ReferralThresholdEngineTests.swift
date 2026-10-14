@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultReferralThresholdEngine(Kit.Flags.newRegistry())
        let item = Referrals.newReferralThreshold("code-728", name: "name-876")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
