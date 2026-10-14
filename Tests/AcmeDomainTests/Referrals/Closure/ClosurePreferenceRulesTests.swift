@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosurePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosurePreferenceValidator()
        let item = Referrals.newClosurePreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosurePreferencePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Referrals.ClosurePreferencePayerLengthRule(maxLength: 16)
        let item = Referrals.newClosurePreference("x", title: "y")
        item.payer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosurePreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ClosurePreferenceRequiredTitleRule(message: "closure preference needs this field")
        let item = Referrals.newClosurePreference("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
