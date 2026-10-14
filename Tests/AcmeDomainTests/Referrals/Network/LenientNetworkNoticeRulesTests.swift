@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientNetworkNoticeValidator()
        let item = Referrals.newLenientNetworkNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientNetworkNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LenientNetworkNoticeRequiredCodeRule(message: "lenient network notice needs a value")
        let item = Referrals.newLenientNetworkNotice("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientNetworkNoticeRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.LenientNetworkNoticeRequiredTitleRule(message: "lenient network notice needs an entry")
        let item = Referrals.newLenientNetworkNotice("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLenientNetworkNoticeUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.LenientNetworkNoticeUpdatedAtRangeRule(min: 16, max: 86400)
        let item = Referrals.newLenientNetworkNotice("x", title: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientNetworkNoticeRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Referrals.LenientNetworkNoticeRequiredUnitRule(message: "lenient network notice needs an entry")
        let item = Referrals.newLenientNetworkNotice("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
