@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSlotRollupEngine(Kit.Flags.newRegistry())
        let item = Referrals.newSlotRollup("code-508", title: "title-190")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
