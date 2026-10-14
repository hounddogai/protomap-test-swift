@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultDefaultRiskScoreWindowEngine()
        let item = CareManagement.newDefaultRiskScoreWindow("code-916", title: "title-530")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
