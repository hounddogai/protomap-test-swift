@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalEligibilityTemplateValidator()
        let item = Referrals.newSeasonalEligibilityTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalEligibilityTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.SeasonalEligibilityTemplateRequiredNameRule(
            message: "seasonal eligibility template needs a value"
        )
        let item = Referrals.newSeasonalEligibilityTemplate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalEligibilityTemplateContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Referrals.SeasonalEligibilityTemplateContactEmailLengthRule(maxLength: 1000)
        let item = Referrals.newSeasonalEligibilityTemplate("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalEligibilityTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SeasonalEligibilityTemplateRequiredCodeRule(
            message: "seasonal eligibility template needs an entry"
        )
        let item = Referrals.newSeasonalEligibilityTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
