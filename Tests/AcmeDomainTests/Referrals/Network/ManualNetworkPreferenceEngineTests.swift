@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualNetworkPreferenceEngine(Kit.Flags.newRegistry())
        let item = Referrals.newManualNetworkPreference("code-669", title: "title-347")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
