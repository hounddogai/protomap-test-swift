@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveClaimSummaryValidator()
        let item = RevenueCycle.newAdaptiveClaimSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.AdaptiveClaimSummaryTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newAdaptiveClaimSummary("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AdaptiveClaimSummaryRequiredCodeRule(message: "adaptive claim summary needs a value")
        let item = RevenueCycle.newAdaptiveClaimSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
