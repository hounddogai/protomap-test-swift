@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualClosureRollupEngine(Kit.Flags.newRegistry())
        let item = Referrals.newManualClosureRollup("code-955", title: "title-684")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
