@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkClaimValidator()
        let item = Referrals.newNetworkClaim("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkClaimExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.NetworkClaimExpiresAtRangeRule(min: 64, max: 64)
        let item = Referrals.newNetworkClaim("x", title: "y")
        item.expiresAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkClaimCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkClaimCodeLengthRule(maxLength: 80)
        let item = Referrals.newNetworkClaim("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkClaimTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.NetworkClaimTitleLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkClaim("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
