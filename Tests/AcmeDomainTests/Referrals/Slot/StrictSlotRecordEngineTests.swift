@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultStrictSlotRecordEngine(Kit.Flags.newRegistry())
        let item = Referrals.newStrictSlotRecord("code-79", label: "label-582")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
