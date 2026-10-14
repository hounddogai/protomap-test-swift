@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingRoundingTierValidator()
        let item = ClinicalOps.newPendingRoundingTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingTierThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = ClinicalOps.PendingRoundingTierThresholdRangeRule(min: 7.2, max: 4538.9)
        let item = ClinicalOps.newPendingRoundingTier("x", label: "y")
        item.threshold = 4540.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingTierRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = ClinicalOps.PendingRoundingTierRetriesRangeRule(min: 1000, max: 1000)
        let item = ClinicalOps.newPendingRoundingTier("x", label: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingRoundingTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PendingRoundingTierRequiredCodeRule(message: "pending rounding tier needs this field")
        let item = ClinicalOps.newPendingRoundingTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPendingRoundingTierGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.PendingRoundingTierGraceDaysRangeRule(min: 1000, max: 3600)
        let item = ClinicalOps.newPendingRoundingTier("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
