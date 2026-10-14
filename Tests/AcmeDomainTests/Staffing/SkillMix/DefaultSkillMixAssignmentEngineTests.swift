@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixAssignmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultDefaultSkillMixAssignmentEngine(Kit.Flags.newRegistry())
        let item = Staffing.newDefaultSkillMixAssignment("code-550", name: "name-80")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
