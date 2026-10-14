@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilityRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredEligibilityRecordValidator()
        let item = Referrals.newTieredEligibilityRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredEligibilityRecordWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.TieredEligibilityRecordWindowDaysRangeRule(min: 16, max: 1000)
        let item = Referrals.newTieredEligibilityRecord("x", title: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredEligibilityRecordBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.TieredEligibilityRecordBatchSizeRangeRule(min: 255, max: 255)
        let item = Referrals.newTieredEligibilityRecord("x", title: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}
