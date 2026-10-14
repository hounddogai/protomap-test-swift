@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultEligibilityWindowEngine()
        let item = Referrals.newEligibilityWindow("code-121", label: "label-884")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
