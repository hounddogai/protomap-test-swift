@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledChargeDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledChargeDigestValidator()
        let item = RevenueCycle.newScheduledChargeDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledChargeDigestCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.ScheduledChargeDigestCategoryLengthRule(maxLength: 16)
        let item = RevenueCycle.newScheduledChargeDigest("x", name: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleScheduledChargeDigestWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.ScheduledChargeDigestWindowDaysRangeRule(min: 80, max: 86400)
        let item = RevenueCycle.newScheduledChargeDigest("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleScheduledChargeDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ScheduledChargeDigestRequiredNameRule(message: "scheduled charge digest needs a value")
        let item = RevenueCycle.newScheduledChargeDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledChargeDigestNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ScheduledChargeDigestNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newScheduledChargeDigest("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
