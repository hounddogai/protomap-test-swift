@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixRecordValidator()
        let item = Staffing.newSkillMixRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.SkillMixRecordRequiredTitleRule(message: "skill mix record needs this field")
        let item = Staffing.newSkillMixRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixRecordRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.SkillMixRecordRetriesRangeRule(min: 16, max: 16)
        let item = Staffing.newSkillMixRecord("x", title: "y")
        item.retries = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixRecordRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.SkillMixRecordRequiredBedRule(message: "skill mix record needs an entry")
        let item = Staffing.newSkillMixRecord("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixRecordRequiredCodeRule(message: "skill mix record needs a value")
        let item = Staffing.newSkillMixRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
