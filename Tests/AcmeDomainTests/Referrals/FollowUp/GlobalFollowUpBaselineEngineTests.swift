@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultGlobalFollowUpBaselineEngine(Kit.Flags.newRegistry())
        let item = Referrals.newGlobalFollowUpBaseline("code-871", label: "label-438")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
