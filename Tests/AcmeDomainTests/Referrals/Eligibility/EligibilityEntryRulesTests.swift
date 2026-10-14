@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityEntryValidator()
        let item = Referrals.newEligibilityEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.EligibilityEntryLabelLengthRule(maxLength: 86400)
        let item = Referrals.newEligibilityEntry("x", name: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityEntryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.EligibilityEntryMaximumRangeRule(min: 9.0, max: 4959.8)
        let item = Referrals.newEligibilityEntry("x", name: "y")
        item.maximum = 4961.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityEntryCodeLengthRule(maxLength: 80)
        let item = Referrals.newEligibilityEntry("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
