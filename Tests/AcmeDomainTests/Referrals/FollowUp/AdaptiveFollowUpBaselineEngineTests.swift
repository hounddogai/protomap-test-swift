@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveFollowUpBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultAdaptiveFollowUpBaselineEngine(Kit.Flags.newRegistry())
        let item = Referrals.newAdaptiveFollowUpBaseline("code-321", title: "title-742")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
