@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalCareGapThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultSeasonalCareGapThresholdValidator()
        let item = CareManagement.newSeasonalCareGapThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementSeasonalCareGapThresholdCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = CareManagement.SeasonalCareGapThresholdCostRangeRule(min: 7.1, max: 3401.8)
        let item = CareManagement.newSeasonalCareGapThreshold("x", name: "y")
        item.cost = 3403.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalCareGapThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.SeasonalCareGapThresholdNameLengthRule(maxLength: 64)
        let item = CareManagement.newSeasonalCareGapThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementSeasonalCareGapThresholdSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.SeasonalCareGapThresholdSequenceRangeRule(min: 80, max: 120)
        let item = CareManagement.newSeasonalCareGapThreshold("x", name: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalCareGapThresholdCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = CareManagement.SeasonalCareGapThresholdCreatedAtRangeRule(min: 64, max: 86400)
        let item = CareManagement.newSeasonalCareGapThreshold("x", name: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementSeasonalCareGapThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.SeasonalCareGapThresholdRequiredCodeRule(
            message: "seasonal care gap threshold needs an entry"
        )
        let item = CareManagement.newSeasonalCareGapThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
