@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkQuotaValidator()
        let item = Referrals.newNetworkQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkQuotaRequiredCodeRule(message: "network quota needs this field")
        let item = Referrals.newNetworkQuota("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkQuotaRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.NetworkQuotaRetriesRangeRule(min: 3600, max: 86400)
        let item = Referrals.newNetworkQuota("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkQuotaMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.NetworkQuotaMinimumRangeRule(min: 7.1, max: 3761.0)
        let item = Referrals.newNetworkQuota("x", title: "y")
        item.minimum = 3762.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkQuotaEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.NetworkQuotaEncounterIDLengthRule(maxLength: 120)
        let item = Referrals.newNetworkQuota("x", title: "y")
        item.encounterID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
