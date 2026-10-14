@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapTierEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultSeasonalCareGapTierEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newSeasonalCareGapTier("code-904", name: "name-592")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
