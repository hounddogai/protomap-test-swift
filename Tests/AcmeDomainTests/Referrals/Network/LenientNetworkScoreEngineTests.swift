@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLenientNetworkScoreEngine(Kit.Flags.newRegistry())
        let item = Referrals.newLenientNetworkScore("code-6", label: "label-570")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
