@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedSlotBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultCappedSlotBundleEngine()
        let item = Referrals.newCappedSlotBundle("code-981", name: "name-863")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
