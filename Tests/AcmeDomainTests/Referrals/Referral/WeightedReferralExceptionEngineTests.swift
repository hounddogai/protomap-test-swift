@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultWeightedReferralExceptionEngine()
        let item = Referrals.newWeightedReferralException("code-29", title: "title-324")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
