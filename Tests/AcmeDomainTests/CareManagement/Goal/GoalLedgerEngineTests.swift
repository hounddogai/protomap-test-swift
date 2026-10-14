@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGoalLedgerEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newGoalLedger("code-73", name: "name-298")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
