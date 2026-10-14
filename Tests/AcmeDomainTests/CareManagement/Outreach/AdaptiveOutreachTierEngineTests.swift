@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAdaptiveOutreachTierEngine()
        let item = CareManagement.newAdaptiveOutreachTier("code-111", title: "title-196")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
