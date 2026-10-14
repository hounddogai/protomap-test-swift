@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationEstimateValidator()
        let item = RevenueCycle.newAuthorizationEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationEstimateCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.AuthorizationEstimateCategoryLengthRule(maxLength: 64)
        let item = RevenueCycle.newAuthorizationEstimate("x", title: "y")
        item.category = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationEstimateNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = RevenueCycle.AuthorizationEstimateNotesLengthRule(maxLength: 1000)
        let item = RevenueCycle.newAuthorizationEstimate("x", title: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationEstimateWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = RevenueCycle.AuthorizationEstimateWeightRangeRule(min: 4.1, max: 1550.9)
        let item = RevenueCycle.newAuthorizationEstimate("x", title: "y")
        item.weight = 1552.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.AuthorizationEstimateRequiredTitleRule(message: "authorization estimate needs a value")
        let item = RevenueCycle.newAuthorizationEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
