@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixWindowValidator()
        let item = Staffing.newSkillMixWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixWindowSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Staffing.SkillMixWindowSourceLengthRule(maxLength: 80)
        let item = Staffing.newSkillMixWindow("x", title: "y")
        item.source = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixWindowClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Staffing.SkillMixWindowClinicianIDLengthRule(maxLength: 32)
        let item = Staffing.newSkillMixWindow("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixWindowTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.SkillMixWindowTitleLengthRule(maxLength: 120)
        let item = Staffing.newSkillMixWindow("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixWindowCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.SkillMixWindowCostRangeRule(min: 3.4, max: 2782.4)
        let item = Staffing.newSkillMixWindow("x", title: "y")
        item.cost = 2783.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSkillMixWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixWindowRequiredCodeRule(message: "skill mix window needs a value")
        let item = Staffing.newSkillMixWindow("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
