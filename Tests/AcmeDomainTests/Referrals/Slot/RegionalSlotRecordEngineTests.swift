@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultRegionalSlotRecordEngine()
        let item = Referrals.newRegionalSlotRecord("code-461", name: "name-740")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
