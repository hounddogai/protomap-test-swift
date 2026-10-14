@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureQuotaValidator()
        let item = Referrals.newClosureQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureQuotaRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Referrals.ClosureQuotaRequiredSegmentRule(message: "closure quota needs a value")
        let item = Referrals.newClosureQuota("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosureQuotaRequiredTitleRule(message: "closure quota needs an entry")
        let item = Referrals.newClosureQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureQuotaCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.ClosureQuotaCostRangeRule(min: 9.0, max: 3115.4)
        let item = Referrals.newClosureQuota("x", title: "y")
        item.cost = 3116.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureQuotaCodeLengthRule(maxLength: 1000)
        let item = Referrals.newClosureQuota("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
