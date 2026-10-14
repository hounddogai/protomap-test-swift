@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultPrimaryReferralExceptionEngine(Kit.Flags.newRegistry())
        let item = Referrals.newPrimaryReferralException("code-4", title: "title-554")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
