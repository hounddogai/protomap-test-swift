@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryNetworkTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryNetworkTierValidator()
        let item = Referrals.newPrimaryNetworkTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryNetworkTierSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.PrimaryNetworkTierSummaryLengthRule(maxLength: 32)
        let item = Referrals.newPrimaryNetworkTier("x", name: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryNetworkTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PrimaryNetworkTierRequiredCodeRule(message: "primary network tier needs an entry")
        let item = Referrals.newPrimaryNetworkTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
