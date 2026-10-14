@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultClosureEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultDefaultClosureEntryEngine(Kit.Flags.newRegistry())
        let item = Referrals.newDefaultClosureEntry("code-396", title: "title-453")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
