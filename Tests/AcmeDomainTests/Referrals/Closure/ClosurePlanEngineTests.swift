@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultClosurePlanEngine(Kit.Flags.newRegistry())
        let item = Referrals.newClosurePlan("code-152", name: "name-875")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
