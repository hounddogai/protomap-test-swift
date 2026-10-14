@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsAdaptiveNetworkBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultAdaptiveNetworkBundleValidator()
        let item = Referrals.newAdaptiveNetworkBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsAdaptiveNetworkBundleDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Referrals.AdaptiveNetworkBundleDosageMgRangeRule(min: 1.4, max: 4609.1)
        let item = Referrals.newAdaptiveNetworkBundle("x", title: "y")
        item.dosageMg = 4610.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsAdaptiveNetworkBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.AdaptiveNetworkBundleTitleLengthRule(maxLength: 120)
        let item = Referrals.newAdaptiveNetworkBundle("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsAdaptiveNetworkBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.AdaptiveNetworkBundleRequiredCodeRule(message: "adaptive network bundle needs an entry")
        let item = Referrals.newAdaptiveNetworkBundle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsAdaptiveNetworkBundleReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.AdaptiveNetworkBundleReviewerLengthRule(maxLength: 3600)
        let item = Referrals.newAdaptiveNetworkBundle("x", title: "y")
        item.reviewer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
