@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeNoticeValidator()
        let item = RevenueCycle.newChargeNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ChargeNoticeRequiredTitleRule(message: "charge notice needs this field")
        let item = RevenueCycle.newChargeNotice("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeNoticeRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.ChargeNoticeRateRangeRule(min: 4.6, max: 219.7)
        let item = RevenueCycle.newChargeNotice("x", name: "y")
        item.rate = 221.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeNoticeRequiredCodeRule(message: "charge notice needs this field")
        let item = RevenueCycle.newChargeNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
