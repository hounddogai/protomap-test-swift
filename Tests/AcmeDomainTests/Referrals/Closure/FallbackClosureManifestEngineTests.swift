@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultFallbackClosureManifestEngine(Kit.Flags.newRegistry())
        let item = Referrals.newFallbackClosureManifest("code-867", label: "label-122")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
