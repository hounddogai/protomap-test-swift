@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRiskScoreWindowEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRiskScoreWindow("code-516", title: "title-105")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
