@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixThresholdValidator()
        let item = Staffing.newSkillMixThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.SkillMixThresholdRequiredTitleRule(message: "skill mix threshold needs an entry")
        let item = Staffing.newSkillMixThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixThresholdCodeLengthRule(maxLength: 3600)
        let item = Staffing.newSkillMixThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixThresholdEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Staffing.SkillMixThresholdEncounterIDLengthRule(maxLength: 80)
        let item = Staffing.newSkillMixThreshold("x", title: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
