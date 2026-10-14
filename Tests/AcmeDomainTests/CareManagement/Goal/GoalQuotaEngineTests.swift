@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGoalQuotaEngine()
        let item = CareManagement.newGoalQuota("code-909", label: "label-584")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
