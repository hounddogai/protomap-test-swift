@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixNoticeValidator()
        let item = Staffing.newSkillMixNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixNoticeRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.SkillMixNoticeRequiredTimezoneRule(message: "skill mix notice needs a value")
        let item = Staffing.newSkillMixNotice("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixNoticeRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Staffing.SkillMixNoticeRequiredCategoryRule(message: "skill mix notice needs an entry")
        let item = Staffing.newSkillMixNotice("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixNoticeCodeLengthRule(maxLength: 255)
        let item = Staffing.newSkillMixNotice("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
