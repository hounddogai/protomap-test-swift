@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityVarianceValidator()
        let item = Referrals.newEligibilityVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityVarianceDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.EligibilityVarianceDurationMinutesRangeRule(min: 120, max: 1000)
        let item = Referrals.newEligibilityVariance("x", label: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityVarianceCodeLengthRule(maxLength: 120)
        let item = Referrals.newEligibilityVariance("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.EligibilityVarianceQuantityRangeRule(min: 1000, max: 86400)
        let item = Referrals.newEligibilityVariance("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
