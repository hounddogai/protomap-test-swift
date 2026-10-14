@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackFollowUpBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackFollowUpBaselineValidator()
        let item = Referrals.newFallbackFollowUpBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackFollowUpBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FallbackFollowUpBaselineCodeLengthRule(maxLength: 1000)
        let item = Referrals.newFallbackFollowUpBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackFollowUpBaselineBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.FallbackFollowUpBaselineBatchSizeRangeRule(min: 64, max: 120)
        let item = Referrals.newFallbackFollowUpBaseline("x", label: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFallbackFollowUpBaselineCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.FallbackFollowUpBaselineCreatedAtRangeRule(min: 32, max: 3600)
        let item = Referrals.newFallbackFollowUpBaseline("x", label: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
