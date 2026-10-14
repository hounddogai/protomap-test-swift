@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultAdaptiveNetworkDraftEngine(Kit.Flags.newRegistry())
        let item = Referrals.newAdaptiveNetworkDraft("code-891", name: "name-541")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
