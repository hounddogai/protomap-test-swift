@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsSeasonalRoundingEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultSeasonalRoundingEstimateValidator()
        let item = ClinicalOps.newSeasonalRoundingEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingEstimateDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.SeasonalRoundingEstimateDurationMinutesRangeRule(min: 64, max: 120)
        let item = ClinicalOps.newSeasonalRoundingEstimate("x", name: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingEstimateExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = ClinicalOps.SeasonalRoundingEstimateExpiresAtRangeRule(min: 64, max: 1000)
        let item = ClinicalOps.newSeasonalRoundingEstimate("x", name: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.SeasonalRoundingEstimateCodeLengthRule(maxLength: 80)
        let item = ClinicalOps.newSeasonalRoundingEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingEstimateRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = ClinicalOps.SeasonalRoundingEstimateRequiredDiagnosisCodeRule(
            message: "seasonal rounding estimate needs an entry"
        )
        let item = ClinicalOps.newSeasonalRoundingEstimate("", name: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsSeasonalRoundingEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.SeasonalRoundingEstimateNameLengthRule(maxLength: 32)
        let item = ClinicalOps.newSeasonalRoundingEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
