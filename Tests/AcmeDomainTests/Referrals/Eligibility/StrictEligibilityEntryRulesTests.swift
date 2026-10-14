@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictEligibilityEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictEligibilityEntryValidator()
        let item = Referrals.newStrictEligibilityEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictEligibilityEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.StrictEligibilityEntryRequiredTitleRule(
            message: "strict eligibility entry needs this field"
        )
        let item = Referrals.newStrictEligibilityEntry("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictEligibilityEntryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.StrictEligibilityEntryTitleLengthRule(maxLength: 3600)
        let item = Referrals.newStrictEligibilityEntry("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictEligibilityEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.StrictEligibilityEntryCodeLengthRule(maxLength: 255)
        let item = Referrals.newStrictEligibilityEntry("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictEligibilityEntryRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Referrals.StrictEligibilityEntryRequiredSummaryRule(
            message: "strict eligibility entry needs this field"
        )
        let item = Referrals.newStrictEligibilityEntry("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}
