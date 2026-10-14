@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredSkillMixReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultTieredSkillMixReservationEngine(Kit.Flags.newRegistry())
        let item = Staffing.newTieredSkillMixReservation("code-172", title: "title-874")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
