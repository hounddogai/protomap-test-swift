@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedClosureRequestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultCappedClosureRequestEngine()
        let item = Referrals.newCappedClosureRequest("code-557", title: "title-916")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
