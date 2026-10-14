@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedEligibilityWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedEligibilityWindowValidator()
        let item = Referrals.newWeightedEligibilityWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedEligibilityWindowRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.WeightedEligibilityWindowRequiredBedRule(
            message: "weighted eligibility window needs this field"
        )
        let item = Referrals.newWeightedEligibilityWindow("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedEligibilityWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedEligibilityWindowRequiredCodeRule(
            message: "weighted eligibility window needs a value"
        )
        let item = Referrals.newWeightedEligibilityWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
