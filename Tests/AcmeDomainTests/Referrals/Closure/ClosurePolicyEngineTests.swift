@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultClosurePolicyEngine(Kit.Flags.newRegistry())
        let item = Referrals.newClosurePolicy("code-347", label: "label-94")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
