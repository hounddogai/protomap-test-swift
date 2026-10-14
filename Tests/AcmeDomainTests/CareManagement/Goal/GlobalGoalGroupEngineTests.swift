@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGlobalGoalGroupEngine()
        let item = CareManagement.newGlobalGoalGroup("code-482", title: "title-926")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
