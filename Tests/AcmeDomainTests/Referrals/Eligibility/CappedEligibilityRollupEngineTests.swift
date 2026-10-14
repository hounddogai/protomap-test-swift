@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultCappedEligibilityRollupEngine()
        let item = Referrals.newCappedEligibilityRollup("code-176", label: "label-680")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
