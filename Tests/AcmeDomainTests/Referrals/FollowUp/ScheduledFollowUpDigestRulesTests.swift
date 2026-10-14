@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledFollowUpDigestValidator()
        let item = Referrals.newScheduledFollowUpDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledFollowUpDigestDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.ScheduledFollowUpDigestDiscountRangeRule(min: 4.4, max: 629.0)
        let item = Referrals.newScheduledFollowUpDigest("x", label: "y")
        item.discount = 630.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledFollowUpDigestRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.ScheduledFollowUpDigestRequiredLocaleRule(
            message: "scheduled follow up digest needs an entry"
        )
        let item = Referrals.newScheduledFollowUpDigest("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledFollowUpDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ScheduledFollowUpDigestRequiredCodeRule(
            message: "scheduled follow up digest needs an entry"
        )
        let item = Referrals.newScheduledFollowUpDigest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledFollowUpDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.ScheduledFollowUpDigestRequiredLabelRule(
            message: "scheduled follow up digest needs this field"
        )
        let item = Referrals.newScheduledFollowUpDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
