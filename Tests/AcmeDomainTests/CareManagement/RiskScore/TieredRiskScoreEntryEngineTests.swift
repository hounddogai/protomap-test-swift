@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredRiskScoreEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultTieredRiskScoreEntryEngine()
        let item = CareManagement.newTieredRiskScoreEntry("code-490", name: "name-618")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
