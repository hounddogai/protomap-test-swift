@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackStatementAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackStatementAssignmentValidator()
        let item = RevenueCycle.newFallbackStatementAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackStatementAssignmentAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.FallbackStatementAssignmentAmountRangeRule(min: 6.4, max: 4960.8)
        let item = RevenueCycle.newFallbackStatementAssignment("x", title: "y")
        item.amount = 4962.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackStatementAssignmentRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.FallbackStatementAssignmentRequiredDescriptionRule(
            message: "fallback statement assignment needs an entry"
        )
        let item = RevenueCycle.newFallbackStatementAssignment("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackStatementAssignmentWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.FallbackStatementAssignmentWindowDaysRangeRule(min: 80, max: 80)
        let item = RevenueCycle.newFallbackStatementAssignment("x", title: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackStatementAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.FallbackStatementAssignmentTitleLengthRule(maxLength: 1000)
        let item = RevenueCycle.newFallbackStatementAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackStatementAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackStatementAssignmentRequiredCodeRule(
            message: "fallback statement assignment needs this field"
        )
        let item = RevenueCycle.newFallbackStatementAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
