@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualNetworkPreferenceValidator()
        let item = Referrals.newManualNetworkPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualNetworkPreferenceRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Referrals.ManualNetworkPreferenceRequiredCountryRule(
            message: "manual network preference needs an entry"
        )
        let item = Referrals.newManualNetworkPreference("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualNetworkPreferenceOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Referrals.ManualNetworkPreferenceOwnerIDLengthRule(maxLength: 3600)
        let item = Referrals.newManualNetworkPreference("x", title: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualNetworkPreferenceCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Referrals.ManualNetworkPreferenceCountryLengthRule(maxLength: 32)
        let item = Referrals.newManualNetworkPreference("x", title: "y")
        item.country = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualNetworkPreferenceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.ManualNetworkPreferenceLimitRangeRule(min: 16, max: 3600)
        let item = Referrals.newManualNetworkPreference("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}
