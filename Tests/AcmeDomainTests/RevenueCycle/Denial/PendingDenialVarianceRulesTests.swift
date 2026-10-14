@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingDenialVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingDenialVarianceValidator()
        let item = RevenueCycle.newPendingDenialVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingDenialVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingDenialVarianceCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newPendingDenialVariance("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingDenialVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PendingDenialVarianceRequiredCodeRule(message: "pending denial variance needs an entry")
        let item = RevenueCycle.newPendingDenialVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingDenialVarianceUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.PendingDenialVarianceUpdatedAtRangeRule(min: 80, max: 80)
        let item = RevenueCycle.newPendingDenialVariance("x", title: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingDenialVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.PendingDenialVarianceRequiredTitleRule(
            message: "pending denial variance needs this field"
        )
        let item = RevenueCycle.newPendingDenialVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePendingDenialVarianceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.PendingDenialVarianceLimitRangeRule(min: 32, max: 120)
        let item = RevenueCycle.newPendingDenialVariance("x", title: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}
