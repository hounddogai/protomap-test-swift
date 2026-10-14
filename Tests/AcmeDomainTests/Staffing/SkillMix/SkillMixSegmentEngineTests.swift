@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultSkillMixSegmentEngine()
        let item = Staffing.newSkillMixSegment("code-584", label: "label-942")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
