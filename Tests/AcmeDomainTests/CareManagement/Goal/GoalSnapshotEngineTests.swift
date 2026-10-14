@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGoalSnapshotEngine()
        let item = CareManagement.newGoalSnapshot("code-401", label: "label-899")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
