@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultNetworkOverrideEngine(Kit.Flags.newRegistry())
        let item = Referrals.newNetworkOverride("code-542", name: "name-201")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
