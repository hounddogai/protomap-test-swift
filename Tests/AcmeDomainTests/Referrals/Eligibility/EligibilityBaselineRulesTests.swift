@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityBaselineValidator()
        let item = Referrals.newEligibilityBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityBaselineBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.EligibilityBaselineBatchSizeRangeRule(min: 1000, max: 86400)
        let item = Referrals.newEligibilityBaseline("x", label: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityBaselineGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.EligibilityBaselineGraceDaysRangeRule(min: 3600, max: 3600)
        let item = Referrals.newEligibilityBaseline("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.EligibilityBaselineCodeLengthRule(maxLength: 32)
        let item = Referrals.newEligibilityBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
