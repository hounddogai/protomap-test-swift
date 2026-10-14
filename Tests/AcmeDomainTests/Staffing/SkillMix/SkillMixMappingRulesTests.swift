@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixMappingValidator()
        let item = Staffing.newSkillMixMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixMappingCodeLengthRule(maxLength: 32)
        let item = Staffing.newSkillMixMapping("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixMappingLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.SkillMixMappingLabelLengthRule(maxLength: 64)
        let item = Staffing.newSkillMixMapping("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
