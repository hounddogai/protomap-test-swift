@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultClosureEstimateEngine(Kit.Flags.newRegistry())
        let item = Referrals.newClosureEstimate("code-332", name: "name-663")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
