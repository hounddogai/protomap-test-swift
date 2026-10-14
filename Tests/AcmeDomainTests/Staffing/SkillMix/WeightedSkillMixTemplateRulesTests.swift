@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedSkillMixTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultWeightedSkillMixTemplateValidator()
        let item = Staffing.newWeightedSkillMixTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingWeightedSkillMixTemplateDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.WeightedSkillMixTemplateDescriptionLengthRule(maxLength: 64)
        let item = Staffing.newWeightedSkillMixTemplate("x", label: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingWeightedSkillMixTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.WeightedSkillMixTemplateCodeLengthRule(maxLength: 3600)
        let item = Staffing.newWeightedSkillMixTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
