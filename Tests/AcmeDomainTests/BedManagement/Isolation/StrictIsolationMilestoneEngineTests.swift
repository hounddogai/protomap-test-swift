@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultStrictIsolationMilestoneEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newStrictIsolationMilestone("code-738", name: "name-939")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
