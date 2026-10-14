@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualNetworkPolicyEngine()
        let item = Referrals.newManualNetworkPolicy("code-960", name: "name-921")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
