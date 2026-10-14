@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFallbackFloatPoolMilestoneEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFallbackFloatPoolMilestone("code-45", name: "name-414")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
