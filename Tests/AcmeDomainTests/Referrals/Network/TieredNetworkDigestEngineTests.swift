@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredNetworkDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultTieredNetworkDigestEngine(Kit.Flags.newRegistry())
        let item = Referrals.newTieredNetworkDigest("code-905", name: "name-613")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
