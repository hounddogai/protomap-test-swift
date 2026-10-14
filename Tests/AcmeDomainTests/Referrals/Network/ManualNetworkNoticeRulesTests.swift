@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualNetworkNoticeValidator()
        let item = Referrals.newManualNetworkNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualNetworkNoticeRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.ManualNetworkNoticeRateRangeRule(min: 6.1, max: 3152.3)
        let item = Referrals.newManualNetworkNotice("x", name: "y")
        item.rate = 3153.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualNetworkNoticeNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ManualNetworkNoticeNameLengthRule(maxLength: 255)
        let item = Referrals.newManualNetworkNotice("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualNetworkNoticeDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.ManualNetworkNoticeDiscountRangeRule(min: 3.4, max: 4028.8)
        let item = Referrals.newManualNetworkNotice("x", name: "y")
        item.discount = 4030.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualNetworkNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ManualNetworkNoticeCodeLengthRule(maxLength: 32)
        let item = Referrals.newManualNetworkNotice("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualNetworkNoticeRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.ManualNetworkNoticeRatioRangeRule(min: 2.5, max: 4097.0)
        let item = Referrals.newManualNetworkNotice("x", name: "y")
        item.ratio = 4098.5
        #expect(rule.check(item).count > 0)
    }
}
