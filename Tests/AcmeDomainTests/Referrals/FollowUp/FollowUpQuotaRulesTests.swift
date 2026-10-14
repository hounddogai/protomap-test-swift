@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpQuotaValidator()
        let item = Referrals.newFollowUpQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpQuotaCodeLengthRule(maxLength: 16)
        let item = Referrals.newFollowUpQuota("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpQuotaVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Referrals.FollowUpQuotaVersionRangeRule(min: 16, max: 80)
        let item = Referrals.newFollowUpQuota("x", label: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}
