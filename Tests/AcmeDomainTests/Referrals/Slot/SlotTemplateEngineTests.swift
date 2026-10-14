@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSlotTemplateEngine()
        let item = Referrals.newSlotTemplate("code-639", label: "label-752")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
