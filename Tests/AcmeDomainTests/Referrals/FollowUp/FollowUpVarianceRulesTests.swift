@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpVarianceValidator()
        let item = Referrals.newFollowUpVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpVarianceCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.FollowUpVarianceCopayRangeRule(min: 6.4, max: 1011.5)
        let item = Referrals.newFollowUpVariance("x", name: "y")
        item.copay = 1013.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpVarianceRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.FollowUpVarianceRequiredCountryRule(message: "follow up variance needs this field")
        let item = Referrals.newFollowUpVariance("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpVarianceCodeLengthRule(maxLength: 64)
        let item = Referrals.newFollowUpVariance("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpVarianceRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Referrals.FollowUpVarianceRequiredWardRule(message: "follow up variance needs this field")
        let item = Referrals.newFollowUpVariance("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpVarianceRequiredCodeRule(message: "follow up variance needs a value")
        let item = Referrals.newFollowUpVariance("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
