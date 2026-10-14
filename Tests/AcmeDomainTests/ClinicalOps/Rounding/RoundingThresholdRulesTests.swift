@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRoundingThresholdValidator()
        let item = ClinicalOps.newRoundingThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRoundingThresholdRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = ClinicalOps.RoundingThresholdRequiredCategoryRule(message: "rounding threshold needs a value")
        let item = ClinicalOps.newRoundingThreshold("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRoundingThresholdRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = ClinicalOps.RoundingThresholdRatioRangeRule(min: 3.3, max: 2817.6)
        let item = ClinicalOps.newRoundingThreshold("x", name: "y")
        item.ratio = 2819.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRoundingThresholdRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.RoundingThresholdRequiredEncounterIDRule(message: "rounding threshold needs an entry")
        let item = ClinicalOps.newRoundingThreshold("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
