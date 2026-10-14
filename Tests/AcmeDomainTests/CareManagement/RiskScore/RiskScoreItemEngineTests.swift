@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreItemEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRiskScoreItemEngine()
        let item = CareManagement.newRiskScoreItem("code-871", label: "label-454")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
