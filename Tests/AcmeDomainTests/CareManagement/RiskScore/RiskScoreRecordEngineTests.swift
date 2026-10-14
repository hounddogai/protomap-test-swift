@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRiskScoreRecordEngine()
        let item = CareManagement.newRiskScoreRecord("code-464", name: "name-858")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
