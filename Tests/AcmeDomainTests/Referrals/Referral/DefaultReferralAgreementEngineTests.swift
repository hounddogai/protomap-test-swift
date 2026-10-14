@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultReferralAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultDefaultReferralAgreementEngine()
        let item = Referrals.newDefaultReferralAgreement("code-566", name: "name-890")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
