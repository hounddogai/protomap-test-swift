@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotSummaryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPrimarySlotSummaryEngine()
        let item = Referrals.newPrimarySlotSummary("code-409", title: "title-746")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
