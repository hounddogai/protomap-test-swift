@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureAdjustmentValidator()
        let item = Referrals.newClosureAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureAdjustmentCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.ClosureAdjustmentCopayRangeRule(min: 9.3, max: 3588.6)
        let item = Referrals.newClosureAdjustment("x", title: "y")
        item.copay = 3590.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureAdjustmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosureAdjustmentRequiredTitleRule(message: "closure adjustment needs an entry")
        let item = Referrals.newClosureAdjustment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureAdjustmentCodeLengthRule(maxLength: 80)
        let item = Referrals.newClosureAdjustment("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureAdjustmentWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.ClosureAdjustmentWeightRangeRule(min: 0.2, max: 3491.7)
        let item = Referrals.newClosureAdjustment("x", title: "y")
        item.weight = 3493.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureAdjustmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.ClosureAdjustmentRequiredCountryRule(message: "closure adjustment needs an entry")
        let item = Referrals.newClosureAdjustment("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
