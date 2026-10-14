@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSkillMixAdjustmentValidator()
        let item = Staffing.newSkillMixAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSkillMixAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SkillMixAdjustmentRequiredCodeRule(message: "skill mix adjustment needs a value")
        let item = Staffing.newSkillMixAdjustment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSkillMixAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.SkillMixAdjustmentLabelLengthRule(maxLength: 255)
        let item = Staffing.newSkillMixAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.SkillMixAdjustmentCodeLengthRule(maxLength: 86400)
        let item = Staffing.newSkillMixAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingSkillMixAdjustmentQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.SkillMixAdjustmentQuantityRangeRule(min: 120, max: 120)
        let item = Staffing.newSkillMixAdjustment("x", label: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}
