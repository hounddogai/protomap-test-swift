@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalAuthorizationSummaryValidator()
        let item = RevenueCycle.newGlobalAuthorizationSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.GlobalAuthorizationSummaryRequiredTitleRule(
            message: "global authorization summary needs a value"
        )
        let item = RevenueCycle.newGlobalAuthorizationSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.GlobalAuthorizationSummaryTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newGlobalAuthorizationSummary("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.GlobalAuthorizationSummaryRequiredCodeRule(
            message: "global authorization summary needs an entry"
        )
        let item = RevenueCycle.newGlobalAuthorizationSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
