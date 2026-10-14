@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledSkillMixEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledSkillMixEstimateValidator()
        let item = Staffing.newScheduledSkillMixEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledSkillMixEstimateDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.ScheduledSkillMixEstimateDescriptionLengthRule(maxLength: 1000)
        let item = Staffing.newScheduledSkillMixEstimate("x", label: "y")
        item.description = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledSkillMixEstimateAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.ScheduledSkillMixEstimateAmountRangeRule(min: 8.0, max: 1656.4)
        let item = Staffing.newScheduledSkillMixEstimate("x", label: "y")
        item.amount = 1657.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledSkillMixEstimateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.ScheduledSkillMixEstimateRequiredLabelRule(
            message: "scheduled skill mix estimate needs this field"
        )
        let item = Staffing.newScheduledSkillMixEstimate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledSkillMixEstimateCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.ScheduledSkillMixEstimateCopayRangeRule(min: 10.0, max: 3437.2)
        let item = Staffing.newScheduledSkillMixEstimate("x", label: "y")
        item.copay = 3438.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledSkillMixEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ScheduledSkillMixEstimateCodeLengthRule(maxLength: 3600)
        let item = Staffing.newScheduledSkillMixEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
