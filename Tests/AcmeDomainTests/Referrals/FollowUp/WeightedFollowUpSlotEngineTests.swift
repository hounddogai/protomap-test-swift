@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultWeightedFollowUpSlotEngine(Kit.Flags.newRegistry())
        let item = Referrals.newWeightedFollowUpSlot("code-133", label: "label-330")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
