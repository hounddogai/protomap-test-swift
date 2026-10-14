@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualRiskScoreGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultManualRiskScoreGroupEngine()
        let item = CareManagement.newManualRiskScoreGroup("code-881", label: "label-293")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
