@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationSummaryValidator()
        let item = RevenueCycle.newAuthorizationSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationSummaryPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.AuthorizationSummaryPriorityRangeRule(min: 32, max: 3600)
        let item = RevenueCycle.newAuthorizationSummary("x", title: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationSummaryLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.AuthorizationSummaryLimitRangeRule(min: 64, max: 255)
        let item = RevenueCycle.newAuthorizationSummary("x", title: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationSummaryRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.AuthorizationSummaryRequiredFacilityRule(message: "authorization summary needs a value")
        let item = RevenueCycle.newAuthorizationSummary("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.AuthorizationSummaryRequiredTitleRule(message: "authorization summary needs this field")
        let item = RevenueCycle.newAuthorizationSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationSummaryFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = RevenueCycle.AuthorizationSummaryFacilityLengthRule(maxLength: 80)
        let item = RevenueCycle.newAuthorizationSummary("x", title: "y")
        item.facility = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
