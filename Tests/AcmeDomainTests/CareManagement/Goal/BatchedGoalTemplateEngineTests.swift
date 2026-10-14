@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultBatchedGoalTemplateEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newBatchedGoalTemplate("code-494", name: "name-103")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
