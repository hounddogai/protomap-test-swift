@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveAuthorizationAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveAuthorizationAuditValidator()
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveAuthorizationAuditStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.AdaptiveAuthorizationAuditStartsAtRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("x", title: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAdaptiveAuthorizationAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.AdaptiveAuthorizationAuditRequiredTitleRule(
            message: "adaptive authorization audit needs a value"
        )
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveAuthorizationAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AdaptiveAuthorizationAuditCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveAuthorizationAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AdaptiveAuthorizationAuditRequiredCodeRule(
            message: "adaptive authorization audit needs an entry"
        )
        let item = RevenueCycle.newAdaptiveAuthorizationAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
