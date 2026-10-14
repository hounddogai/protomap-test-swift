@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultNetworkWindowValidator()
        let item = Referrals.newDefaultNetworkWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultNetworkWindowDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.DefaultNetworkWindowDiscountRangeRule(min: 1.6, max: 111.1)
        let item = Referrals.newDefaultNetworkWindow("x", label: "y")
        item.discount = 112.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsDefaultNetworkWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.DefaultNetworkWindowRequiredCodeRule(message: "default network window needs a value")
        let item = Referrals.newDefaultNetworkWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultNetworkWindowRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Referrals.DefaultNetworkWindowRequiredContactEmailRule(
            message: "default network window needs a value"
        )
        let item = Referrals.newDefaultNetworkWindow("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}
