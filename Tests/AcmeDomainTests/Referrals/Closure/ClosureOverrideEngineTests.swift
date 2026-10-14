@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultClosureOverrideEngine()
        let item = Referrals.newClosureOverride("code-510", label: "label-512")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
