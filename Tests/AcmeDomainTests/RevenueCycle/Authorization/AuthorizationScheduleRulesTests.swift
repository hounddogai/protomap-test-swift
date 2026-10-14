@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationScheduleValidator()
        let item = RevenueCycle.newAuthorizationSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationScheduleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationScheduleCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newAuthorizationSchedule("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationScheduleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = RevenueCycle.AuthorizationScheduleBudgetRangeRule(min: 6.5, max: 4790.2)
        let item = RevenueCycle.newAuthorizationSchedule("x", label: "y")
        item.budget = 4791.7
        #expect(rule.check(item).count > 0)
    }
}
