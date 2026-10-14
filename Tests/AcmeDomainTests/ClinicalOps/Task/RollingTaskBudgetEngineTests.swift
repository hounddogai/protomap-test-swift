@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultRollingTaskBudgetEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newRollingTaskBudget("code-956", name: "name-650")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
