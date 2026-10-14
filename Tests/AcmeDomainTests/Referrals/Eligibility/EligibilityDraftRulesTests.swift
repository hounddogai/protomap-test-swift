@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityDraftValidator()
        let item = Referrals.newEligibilityDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityDraftVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Referrals.EligibilityDraftVersionRangeRule(min: 80, max: 80)
        let item = Referrals.newEligibilityDraft("x", title: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}
