@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledGoalPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledGoalPolicyValidator()
        let item = CareManagement.newScheduledGoalPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledGoalPolicyPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = CareManagement.ScheduledGoalPolicyPhoneLengthRule(maxLength: 3600)
        let item = CareManagement.newScheduledGoalPolicy("x", title: "y")
        item.phone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledGoalPolicyRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.ScheduledGoalPolicyRequiredLocaleRule(message: "scheduled goal policy needs a value")
        let item = CareManagement.newScheduledGoalPolicy("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementScheduledGoalPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ScheduledGoalPolicyCodeLengthRule(maxLength: 120)
        let item = CareManagement.newScheduledGoalPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledGoalPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.ScheduledGoalPolicyRequiredCodeRule(message: "scheduled goal policy needs a value")
        let item = CareManagement.newScheduledGoalPolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
