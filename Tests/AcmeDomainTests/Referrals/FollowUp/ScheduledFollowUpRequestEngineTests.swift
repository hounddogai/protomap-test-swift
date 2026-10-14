@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultScheduledFollowUpRequestEngine(Kit.Flags.newRegistry())
        let item = Referrals.newScheduledFollowUpRequest("code-162", label: "label-950")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
