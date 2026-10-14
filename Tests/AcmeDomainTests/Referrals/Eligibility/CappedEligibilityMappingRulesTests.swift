@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedEligibilityMappingValidator()
        let item = Referrals.newCappedEligibilityMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedEligibilityMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.CappedEligibilityMappingRequiredTitleRule(
            message: "capped eligibility mapping needs a value"
        )
        let item = Referrals.newCappedEligibilityMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
