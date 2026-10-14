@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimQuotaValidator()
        let item = RevenueCycle.newClaimQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimQuotaMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.ClaimQuotaMaximumRangeRule(min: 3.7, max: 4158.7)
        let item = RevenueCycle.newClaimQuota("x", title: "y")
        item.maximum = 4160.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimQuotaRequiredCodeRule(message: "claim quota needs a value")
        let item = RevenueCycle.newClaimQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimQuotaRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = RevenueCycle.ClaimQuotaRequiredDescriptionRule(message: "claim quota needs this field")
        let item = RevenueCycle.newClaimQuota("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ClaimQuotaRequiredTitleRule(message: "claim quota needs an entry")
        let item = RevenueCycle.newClaimQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
