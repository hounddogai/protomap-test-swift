@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLenientNetworkWindowEngine(Kit.Flags.newRegistry())
        let item = Referrals.newLenientNetworkWindow("code-315", title: "title-43")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
