@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingSlotTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPendingSlotTargetEngine(Kit.Flags.newRegistry())
        let item = Referrals.newPendingSlotTarget("code-657", name: "name-977")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
