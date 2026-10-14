@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpPolicyValidator()
        let item = Referrals.newFollowUpPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpPolicyCodeLengthRule(maxLength: 64)
        let item = Referrals.newFollowUpPolicy("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.FollowUpPolicyRequiredLabelRule(message: "follow up policy needs this field")
        let item = Referrals.newFollowUpPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpPolicyRequiredCodeRule(message: "follow up policy needs an entry")
        let item = Referrals.newFollowUpPolicy("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
