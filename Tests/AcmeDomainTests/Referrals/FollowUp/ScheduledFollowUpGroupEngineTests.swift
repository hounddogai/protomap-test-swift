@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultScheduledFollowUpGroupEngine(Kit.Flags.newRegistry())
        let item = Referrals.newScheduledFollowUpGroup("code-413", name: "name-330")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
