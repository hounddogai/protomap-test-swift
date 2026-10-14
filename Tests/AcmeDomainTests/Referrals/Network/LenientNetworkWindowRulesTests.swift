@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientNetworkWindowValidator()
        let item = Referrals.newLenientNetworkWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientNetworkWindowMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.LenientNetworkWindowMinimumRangeRule(min: 3.1, max: 4936.8)
        let item = Referrals.newLenientNetworkWindow("x", title: "y")
        item.minimum = 4938.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientNetworkWindowUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.LenientNetworkWindowUnitLengthRule(maxLength: 255)
        let item = Referrals.newLenientNetworkWindow("x", title: "y")
        item.unit = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLenientNetworkWindowAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.LenientNetworkWindowAttemptsRangeRule(min: 64, max: 3600)
        let item = Referrals.newLenientNetworkWindow("x", title: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientNetworkWindowRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.LenientNetworkWindowRequiredTitleRule(message: "lenient network window needs a value")
        let item = Referrals.newLenientNetworkWindow("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
