@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultDefaultNetworkWindowEngine(Kit.Flags.newRegistry())
        let item = Referrals.newDefaultNetworkWindow("code-239", label: "label-53")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
