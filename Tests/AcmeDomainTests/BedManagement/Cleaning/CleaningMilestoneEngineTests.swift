@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCleaningMilestoneEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCleaningMilestone("code-311", name: "name-172")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
