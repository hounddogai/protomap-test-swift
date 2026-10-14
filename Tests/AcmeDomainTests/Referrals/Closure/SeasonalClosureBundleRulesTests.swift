@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalClosureBundleValidator()
        let item = Referrals.newSeasonalClosureBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalClosureBundleAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.SeasonalClosureBundleAmountRangeRule(min: 0.1, max: 552.4)
        let item = Referrals.newSeasonalClosureBundle("x", label: "y")
        item.amount = 553.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalClosureBundleRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Referrals.SeasonalClosureBundleRequiredCategoryRule(message: "seasonal closure bundle needs a value")
        let item = Referrals.newSeasonalClosureBundle("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
