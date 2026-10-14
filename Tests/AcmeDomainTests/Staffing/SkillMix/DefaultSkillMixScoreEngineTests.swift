@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultSkillMixScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultDefaultSkillMixScoreEngine(Kit.Flags.newRegistry())
        let item = Staffing.newDefaultSkillMixScore("code-644", title: "title-260")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
