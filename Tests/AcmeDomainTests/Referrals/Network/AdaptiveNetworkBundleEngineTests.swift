@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultAdaptiveNetworkBundleEngine()
        let item = Referrals.newAdaptiveNetworkBundle("code-457", title: "title-31")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
