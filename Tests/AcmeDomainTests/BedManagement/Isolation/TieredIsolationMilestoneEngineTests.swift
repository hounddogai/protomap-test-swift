@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTieredIsolationMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTieredIsolationMilestoneEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newTieredIsolationMilestone("code-161", name: "name-875")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
