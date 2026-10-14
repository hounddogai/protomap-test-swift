@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSkillMixCheckpointEngine()
        let item = Staffing.newSkillMixCheckpoint("code-124", title: "title-87")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
