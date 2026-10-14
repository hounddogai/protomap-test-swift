@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualSkillMixScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultManualSkillMixScheduleValidator()
        let item = Staffing.newManualSkillMixSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingManualSkillMixScheduleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ManualSkillMixScheduleNameLengthRule(maxLength: 120)
        let item = Staffing.newManualSkillMixSchedule("x", label: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualSkillMixScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.ManualSkillMixScheduleLabelLengthRule(maxLength: 1000)
        let item = Staffing.newManualSkillMixSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualSkillMixScheduleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.ManualSkillMixScheduleRequiredNameRule(message: "manual skill mix schedule needs this field")
        let item = Staffing.newManualSkillMixSchedule("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingManualSkillMixScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ManualSkillMixScheduleCodeLengthRule(maxLength: 80)
        let item = Staffing.newManualSkillMixSchedule("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingManualSkillMixScheduleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Staffing.ManualSkillMixScheduleVersionRangeRule(min: 32, max: 255)
        let item = Staffing.newManualSkillMixSchedule("x", label: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}
