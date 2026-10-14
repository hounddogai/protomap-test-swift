@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultEligibilityAgreementEngine()
        let item = Referrals.newEligibilityAgreement("code-648", title: "title-430")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
