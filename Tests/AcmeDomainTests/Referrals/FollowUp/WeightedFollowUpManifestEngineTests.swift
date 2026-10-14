@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultWeightedFollowUpManifestEngine(Kit.Flags.newRegistry())
        let item = Referrals.newWeightedFollowUpManifest("code-762", title: "title-198")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
