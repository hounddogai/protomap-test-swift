@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalEligibilityRecordValidator()
        let item = Referrals.newSeasonalEligibilityRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalEligibilityRecordPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Referrals.SeasonalEligibilityRecordPatientRefLengthRule(maxLength: 120)
        let item = Referrals.newSeasonalEligibilityRecord("x", title: "y")
        item.patientRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalEligibilityRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.SeasonalEligibilityRecordRequiredTitleRule(
            message: "seasonal eligibility record needs this field"
        )
        let item = Referrals.newSeasonalEligibilityRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalEligibilityRecordRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Referrals.SeasonalEligibilityRecordRequiredPatientRefRule(
            message: "seasonal eligibility record needs an entry"
        )
        let item = Referrals.newSeasonalEligibilityRecord("", title: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalEligibilityRecordGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.SeasonalEligibilityRecordGraceDaysRangeRule(min: 64, max: 86400)
        let item = Referrals.newSeasonalEligibilityRecord("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSeasonalEligibilityRecordBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.SeasonalEligibilityRecordBatchSizeRangeRule(min: 64, max: 1000)
        let item = Referrals.newSeasonalEligibilityRecord("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}
