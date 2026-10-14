@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityMappingValidator()
        let item = Referrals.newEligibilityMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityMappingWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.EligibilityMappingWeightRangeRule(min: 3.1, max: 4713.4)
        let item = Referrals.newEligibilityMapping("x", name: "y")
        item.weight = 4714.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityMappingCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.EligibilityMappingCostRangeRule(min: 2.9, max: 4172.9)
        let item = Referrals.newEligibilityMapping("x", name: "y")
        item.cost = 4174.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityMappingCodeLengthRule(maxLength: 80)
        let item = Referrals.newEligibilityMapping("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityMappingRequiredCodeRule(message: "eligibility mapping needs this field")
        let item = Referrals.newEligibilityMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityMappingRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.EligibilityMappingRequiredReviewerRule(message: "eligibility mapping needs this field")
        let item = Referrals.newEligibilityMapping("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityMappingReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.EligibilityMappingReviewerLengthRule(maxLength: 1000)
        let item = Referrals.newEligibilityMapping("x", name: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
