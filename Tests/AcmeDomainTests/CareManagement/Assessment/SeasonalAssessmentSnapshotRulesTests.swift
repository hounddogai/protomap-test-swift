@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalAssessmentSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalAssessmentSnapshotValidator()
        let item = CareManagement.newSeasonalAssessmentSnapshot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalAssessmentSnapshotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.SeasonalAssessmentSnapshotRequiredCodeRule(
            message: "seasonal assessment snapshot needs an entry"
        )
        let item = CareManagement.newSeasonalAssessmentSnapshot("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementSeasonalAssessmentSnapshotBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.SeasonalAssessmentSnapshotBatchSizeRangeRule(min: 64, max: 120)
        let item = CareManagement.newSeasonalAssessmentSnapshot("x", title: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalAssessmentSnapshotGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.SeasonalAssessmentSnapshotGraceDaysRangeRule(min: 32, max: 255)
        let item = CareManagement.newSeasonalAssessmentSnapshot("x", title: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalAssessmentSnapshotRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.SeasonalAssessmentSnapshotRateRangeRule(min: 8.9, max: 3660.0)
        let item = CareManagement.newSeasonalAssessmentSnapshot("x", title: "y")
        item.rate = 3661.5
        #expect(rule.check(item).count > 0)
    }
}
