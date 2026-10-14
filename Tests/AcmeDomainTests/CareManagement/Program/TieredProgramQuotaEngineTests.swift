@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredProgramQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultTieredProgramQuotaEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newTieredProgramQuota("code-471", name: "name-767")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
