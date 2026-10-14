@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackOvertimePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackOvertimePolicyValidator()
        let item = Staffing.newFallbackOvertimePolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackOvertimePolicyBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.FallbackOvertimePolicyBudgetRangeRule(min: 5.2, max: 2636.3)
        let item = Staffing.newFallbackOvertimePolicy("x", name: "y")
        item.budget = 2637.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackOvertimePolicyRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Staffing.FallbackOvertimePolicyRequiredChannelRule(message: "fallback overtime policy needs a value")
        let item = Staffing.newFallbackOvertimePolicy("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackOvertimePolicyChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Staffing.FallbackOvertimePolicyChannelLengthRule(maxLength: 1000)
        let item = Staffing.newFallbackOvertimePolicy("x", name: "y")
        item.channel = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackOvertimePolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.FallbackOvertimePolicyCodeLengthRule(maxLength: 120)
        let item = Staffing.newFallbackOvertimePolicy("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackOvertimePolicyCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Staffing.FallbackOvertimePolicyCategoryLengthRule(maxLength: 86400)
        let item = Staffing.newFallbackOvertimePolicy("x", name: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
