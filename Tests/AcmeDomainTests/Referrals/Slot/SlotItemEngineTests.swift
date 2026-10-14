@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotItemEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSlotItemEngine(Kit.Flags.newRegistry())
        let item = Referrals.newSlotItem("code-782", label: "label-562")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
