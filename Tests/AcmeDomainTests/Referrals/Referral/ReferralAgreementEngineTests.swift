@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultReferralAgreementEngine()
        let item = Referrals.newReferralAgreement("code-895", label: "label-831")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
