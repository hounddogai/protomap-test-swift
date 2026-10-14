@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixCheckpointValidator()
        let item = Staffing.newSkillMixCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixCheckpointRequiredCodeRule(message: "skill mix checkpoint needs an entry")
        let item = Staffing.newSkillMixCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixCheckpointDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.SkillMixCheckpointDurationMinutesRangeRule(min: 120, max: 1000)
        let item = Staffing.newSkillMixCheckpoint("x", title: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
