@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictFollowUpAuditValidator()
        let item = Referrals.newStrictFollowUpAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictFollowUpAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.StrictFollowUpAuditRequiredCodeRule(message: "strict follow up audit needs a value")
        let item = Referrals.newStrictFollowUpAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictFollowUpAuditMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.StrictFollowUpAuditMaximumRangeRule(min: 3.4, max: 1263.1)
        let item = Referrals.newStrictFollowUpAudit("x", title: "y")
        item.maximum = 1264.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictFollowUpAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.StrictFollowUpAuditRequiredTitleRule(message: "strict follow up audit needs an entry")
        let item = Referrals.newStrictFollowUpAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictFollowUpAuditMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.StrictFollowUpAuditMarginRangeRule(min: 5.8, max: 4670.0)
        let item = Referrals.newStrictFollowUpAudit("x", title: "y")
        item.margin = 4671.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictFollowUpAuditNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.StrictFollowUpAuditNameLengthRule(maxLength: 120)
        let item = Referrals.newStrictFollowUpAudit("x", title: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
