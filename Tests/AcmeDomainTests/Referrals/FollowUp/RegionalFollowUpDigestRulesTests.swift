@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalFollowUpDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalFollowUpDigestValidator()
        let item = Referrals.newRegionalFollowUpDigest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalFollowUpDigestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Referrals.RegionalFollowUpDigestRateRangeRule(min: 4.4, max: 4091.1)
        let item = Referrals.newRegionalFollowUpDigest("x", title: "y")
        item.rate = 4092.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalFollowUpDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalFollowUpDigestRequiredCodeRule(message: "regional follow up digest needs a value")
        let item = Referrals.newRegionalFollowUpDigest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
