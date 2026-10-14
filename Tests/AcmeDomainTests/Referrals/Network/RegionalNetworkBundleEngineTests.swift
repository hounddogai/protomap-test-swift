@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalNetworkBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRegionalNetworkBundleEngine(Kit.Flags.newRegistry())
        let item = Referrals.newRegionalNetworkBundle("code-94", label: "label-913")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
