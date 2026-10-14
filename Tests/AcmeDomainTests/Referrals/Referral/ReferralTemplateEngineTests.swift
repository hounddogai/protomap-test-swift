@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultReferralTemplateEngine()
        let item = Referrals.newReferralTemplate("code-625", title: "title-697")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
