@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultNetworkPreferenceEngine(Kit.Flags.newRegistry())
        let item = Referrals.newNetworkPreference("code-806", label: "label-272")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
