@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultNetworkPlanEngine(Kit.Flags.newRegistry())
        let item = Referrals.newNetworkPlan("code-434", name: "name-56")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
