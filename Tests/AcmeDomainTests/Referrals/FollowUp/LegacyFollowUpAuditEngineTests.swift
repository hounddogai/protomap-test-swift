@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultLegacyFollowUpAuditEngine(Kit.Flags.newRegistry())
        let item = Referrals.newLegacyFollowUpAudit("code-7", label: "label-82")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
