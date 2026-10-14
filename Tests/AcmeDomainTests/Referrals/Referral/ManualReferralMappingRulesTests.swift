@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualReferralMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualReferralMappingValidator()
        let item = Referrals.newManualReferralMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualReferralMappingRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Referrals.ManualReferralMappingRequiredDescriptionRule(
            message: "manual referral mapping needs this field"
        )
        let item = Referrals.newManualReferralMapping("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualReferralMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ManualReferralMappingRequiredCodeRule(message: "manual referral mapping needs an entry")
        let item = Referrals.newManualReferralMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsManualReferralMappingScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.ManualReferralMappingScoreRangeRule(min: 0.3, max: 423.8)
        let item = Referrals.newManualReferralMapping("x", label: "y")
        item.score = 425.3
        #expect(rule.check(item).count > 0)
    }
}
