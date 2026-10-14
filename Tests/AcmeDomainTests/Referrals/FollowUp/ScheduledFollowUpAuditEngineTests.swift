@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultScheduledFollowUpAuditEngine()
        let item = Referrals.newScheduledFollowUpAudit("code-318", title: "title-169")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
