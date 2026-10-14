@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureDraftEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSeasonalClosureDraftEngine(Kit.Flags.newRegistry())
        let item = Referrals.newSeasonalClosureDraft("code-673", title: "title-87")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
