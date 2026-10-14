@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapSnapshotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultSeasonalCareGapSnapshotEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newSeasonalCareGapSnapshot("code-356", name: "name-780")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
