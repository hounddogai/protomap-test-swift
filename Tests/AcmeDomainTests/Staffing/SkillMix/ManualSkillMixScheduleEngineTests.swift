@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualSkillMixScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultManualSkillMixScheduleEngine(Kit.Flags.newRegistry())
        let item = Staffing.newManualSkillMixSchedule("code-898", label: "label-643")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
