@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultTieredTaskMilestoneEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newTieredTaskMilestone("code-57", name: "name-112")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
