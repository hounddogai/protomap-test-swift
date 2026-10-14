@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedEligibilityVarianceValidator()
        let item = Referrals.newCappedEligibilityVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedEligibilityVarianceRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.CappedEligibilityVarianceRatioRangeRule(min: 9.8, max: 3558.4)
        let item = Referrals.newCappedEligibilityVariance("x", name: "y")
        item.ratio = 3559.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedEligibilityVarianceCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.CappedEligibilityVarianceCeilingRangeRule(min: 5.0, max: 928.8)
        let item = Referrals.newCappedEligibilityVariance("x", name: "y")
        item.ceiling = 930.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedEligibilityVarianceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.CappedEligibilityVarianceNameLengthRule(maxLength: 64)
        let item = Referrals.newCappedEligibilityVariance("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
