@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotBundleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSlotBundleEngine(Kit.Flags.newRegistry())
        let item = Referrals.newSlotBundle("code-584", label: "label-229")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
