@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotBatchEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultStrictSlotBatchEngine()
        let item = Referrals.newStrictSlotBatch("code-351", label: "label-545")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
