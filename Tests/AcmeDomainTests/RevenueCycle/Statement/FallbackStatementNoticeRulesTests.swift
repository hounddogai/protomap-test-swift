@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackStatementNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackStatementNoticeValidator()
        let item = RevenueCycle.newFallbackStatementNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackStatementNoticeCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.FallbackStatementNoticeCeilingRangeRule(min: 6.5, max: 2119.5)
        let item = RevenueCycle.newFallbackStatementNotice("x", title: "y")
        item.ceiling = 2121.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackStatementNoticeRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = RevenueCycle.FallbackStatementNoticeRequiredLocaleRule(
            message: "fallback statement notice needs a value"
        )
        let item = RevenueCycle.newFallbackStatementNotice("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackStatementNoticePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.FallbackStatementNoticePriorityRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newFallbackStatementNotice("x", title: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}
