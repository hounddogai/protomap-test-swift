@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultSeasonalCareGapPlanEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newSeasonalCareGapPlan("code-279", title: "title-477")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
