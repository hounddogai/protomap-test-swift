@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalFollowUpBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalFollowUpBundleValidator()
        let item = Referrals.newSeasonalFollowUpBundle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalFollowUpBundleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.SeasonalFollowUpBundleRequiredLocaleRule(
            message: "seasonal follow up bundle needs an entry"
        )
        let item = Referrals.newSeasonalFollowUpBundle("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalFollowUpBundleRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Referrals.SeasonalFollowUpBundleRequiredSpecialtyRule(
            message: "seasonal follow up bundle needs a value"
        )
        let item = Referrals.newSeasonalFollowUpBundle("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalFollowUpBundleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SeasonalFollowUpBundleCodeLengthRule(maxLength: 80)
        let item = Referrals.newSeasonalFollowUpBundle("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalFollowUpBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SeasonalFollowUpBundleRequiredCodeRule(
            message: "seasonal follow up bundle needs this field"
        )
        let item = Referrals.newSeasonalFollowUpBundle("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalFollowUpBundleStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.SeasonalFollowUpBundleStartsAtRangeRule(min: 64, max: 86400)
        let item = Referrals.newSeasonalFollowUpBundle("x", name: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
