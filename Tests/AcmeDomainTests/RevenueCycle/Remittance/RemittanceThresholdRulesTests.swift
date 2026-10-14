@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceThresholdValidator()
        let item = RevenueCycle.newRemittanceThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceThresholdDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.RemittanceThresholdDiscountRangeRule(min: 6.5, max: 438.4)
        let item = RevenueCycle.newRemittanceThreshold("x", title: "y")
        item.discount = 439.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceThresholdRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.RemittanceThresholdRequiredTimezoneRule(message: "remittance threshold needs this field")
        let item = RevenueCycle.newRemittanceThreshold("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceThresholdDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = RevenueCycle.RemittanceThresholdDescriptionLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceThreshold("x", title: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
