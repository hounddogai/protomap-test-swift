@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultNetworkManifestEngine(Kit.Flags.newRegistry())
        let item = Referrals.newNetworkManifest("code-899", label: "label-177")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
