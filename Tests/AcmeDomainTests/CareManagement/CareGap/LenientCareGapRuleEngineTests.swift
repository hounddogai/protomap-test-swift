@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLenientCareGapRuleEngine()
        let item = CareManagement.newLenientCareGapRule("code-913", name: "name-748")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
