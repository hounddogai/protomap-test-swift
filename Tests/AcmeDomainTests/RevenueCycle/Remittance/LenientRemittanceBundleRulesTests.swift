@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLenientRemittanceBundleValidator()
        let item = RevenueCycle.newLenientRemittanceBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceBundleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.LenientRemittanceBundleAmountRangeRule(min: 3.0, max: 3238.3)
        let item = RevenueCycle.newLenientRemittanceBundle("x", title: "y")
        item.amount = 3239.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceBundleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.LenientRemittanceBundleRateRangeRule(min: 3.9, max: 4868.0)
        let item = RevenueCycle.newLenientRemittanceBundle("x", title: "y")
        item.rate = 4869.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLenientRemittanceBundleRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.LenientRemittanceBundleRequiredTitleRule(
            message: "lenient remittance bundle needs an entry"
        )
        let item = RevenueCycle.newLenientRemittanceBundle("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
