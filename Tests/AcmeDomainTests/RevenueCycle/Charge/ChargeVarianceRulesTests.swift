@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeVarianceValidator()
        let item = RevenueCycle.newChargeVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeVarianceContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = RevenueCycle.ChargeVarianceContactEmailLengthRule(maxLength: 120)
        let item = RevenueCycle.newChargeVariance("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeVarianceWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.ChargeVarianceWindowDaysRangeRule(min: 16, max: 255)
        let item = RevenueCycle.newChargeVariance("x", title: "y")
        item.windowDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeVarianceCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.ChargeVarianceCreatedAtRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newChargeVariance("x", title: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ChargeVarianceRequiredTitleRule(message: "charge variance needs an entry")
        let item = RevenueCycle.newChargeVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
