@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultBatchedOutreachCycleEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newBatchedOutreachCycle("code-377", title: "title-599")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
