@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictEligibilitySlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultStrictEligibilitySlotEngine(Kit.Flags.newRegistry())
        let item = Referrals.newStrictEligibilitySlot("code-701", name: "name-197")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
