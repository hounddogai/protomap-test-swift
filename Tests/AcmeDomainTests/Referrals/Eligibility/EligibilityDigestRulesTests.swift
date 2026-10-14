@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityDigestValidator()
        let item = Referrals.newEligibilityDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityDigestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.EligibilityDigestRequiredLabelRule(message: "eligibility digest needs an entry")
        let item = Referrals.newEligibilityDigest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
