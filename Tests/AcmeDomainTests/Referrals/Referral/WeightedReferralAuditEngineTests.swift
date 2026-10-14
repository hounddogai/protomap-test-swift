@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultWeightedReferralAuditEngine(Kit.Flags.newRegistry())
        let item = Referrals.newWeightedReferralAudit("code-592", name: "name-93")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
