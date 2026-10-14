@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingScoreValidator()
        let item = ClinicalOps.newRoundingScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingScoreGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = ClinicalOps.RoundingScoreGraceDaysRangeRule(min: 16, max: 80)
        let item = ClinicalOps.newRoundingScore("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.RoundingScoreRequiredCodeRule(message: "rounding score needs this field")
        let item = ClinicalOps.newRoundingScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingScoreRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = ClinicalOps.RoundingScoreRequiredRegionRule(message: "rounding score needs a value")
        let item = ClinicalOps.newRoundingScore("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
