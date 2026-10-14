@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualReferralMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualReferralMappingEngine()
        let item = Referrals.newManualReferralMapping("code-82", label: "label-380")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
