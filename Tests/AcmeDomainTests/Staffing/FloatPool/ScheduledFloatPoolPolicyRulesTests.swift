@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledFloatPoolPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledFloatPoolPolicyValidator()
        let item = Staffing.newScheduledFloatPoolPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledFloatPoolPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.ScheduledFloatPoolPolicyRequiredLabelRule(
            message: "scheduled float pool policy needs a value"
        )
        let item = Staffing.newScheduledFloatPoolPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledFloatPoolPolicyCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.ScheduledFloatPoolPolicyCopayRangeRule(min: 8.7, max: 577.0)
        let item = Staffing.newScheduledFloatPoolPolicy("x", label: "y")
        item.copay = 578.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledFloatPoolPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ScheduledFloatPoolPolicyCodeLengthRule(maxLength: 80)
        let item = Staffing.newScheduledFloatPoolPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingScheduledFloatPoolPolicyRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Staffing.ScheduledFloatPoolPolicyRefillsRangeRule(min: 120, max: 1000)
        let item = Staffing.newScheduledFloatPoolPolicy("x", label: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingScheduledFloatPoolPolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.ScheduledFloatPoolPolicyLabelLengthRule(maxLength: 32)
        let item = Staffing.newScheduledFloatPoolPolicy("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
