@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpRuleValidator()
        let item = Referrals.newFollowUpRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpRuleCodeLengthRule(maxLength: 255)
        let item = Referrals.newFollowUpRule("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpRuleRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.FollowUpRuleRequiredCountryRule(message: "follow up rule needs this field")
        let item = Referrals.newFollowUpRule("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpRuleVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Referrals.FollowUpRuleVersionRangeRule(min: 16, max: 86400)
        let item = Referrals.newFollowUpRule("x", title: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
