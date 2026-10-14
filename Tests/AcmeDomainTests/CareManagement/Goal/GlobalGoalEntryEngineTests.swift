@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGlobalGoalEntryEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newGlobalGoalEntry("code-936", label: "label-39")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
