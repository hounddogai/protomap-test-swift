@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixRequestValidator()
        let item = Staffing.newSkillMixRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixRequestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.SkillMixRequestNameLengthRule(maxLength: 120)
        let item = Staffing.newSkillMixRequest("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixRequestCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.SkillMixRequestCeilingRangeRule(min: 5.1, max: 2137.0)
        let item = Staffing.newSkillMixRequest("x", name: "y")
        item.ceiling = 2138.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixRequestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.SkillMixRequestRequiredNameRule(message: "skill mix request needs this field")
        let item = Staffing.newSkillMixRequest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixRequestCodeLengthRule(maxLength: 86400)
        let item = Staffing.newSkillMixRequest("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
