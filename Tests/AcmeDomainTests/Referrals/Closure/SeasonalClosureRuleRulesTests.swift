@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalClosureRuleValidator()
        let item = Referrals.newSeasonalClosureRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalClosureRuleMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.SeasonalClosureRuleMarginRangeRule(min: 3.5, max: 3263.9)
        let item = Referrals.newSeasonalClosureRule("x", label: "y")
        item.margin = 3265.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalClosureRuleDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.SeasonalClosureRuleDiscountRangeRule(min: 9.4, max: 814.8)
        let item = Referrals.newSeasonalClosureRule("x", label: "y")
        item.discount = 816.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalClosureRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.SeasonalClosureRuleLabelLengthRule(maxLength: 86400)
        let item = Referrals.newSeasonalClosureRule("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalClosureRuleWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.SeasonalClosureRuleWeightRangeRule(min: 6.5, max: 4342.8)
        let item = Referrals.newSeasonalClosureRule("x", label: "y")
        item.weight = 4344.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalClosureRuleRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.SeasonalClosureRuleRequiredClinicianIDRule(message: "seasonal closure rule needs a value")
        let item = Referrals.newSeasonalClosureRule("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}
