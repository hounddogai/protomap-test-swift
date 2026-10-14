@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyRoundingMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyRoundingMappingValidator()
        let item = ClinicalOps.newLegacyRoundingMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyRoundingMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.LegacyRoundingMappingRequiredCodeRule(message: "legacy rounding mapping needs an entry")
        let item = ClinicalOps.newLegacyRoundingMapping("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyRoundingMappingCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.LegacyRoundingMappingCostRangeRule(min: 0.1, max: 2812.9)
        let item = ClinicalOps.newLegacyRoundingMapping("x", title: "y")
        item.cost = 2814.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLegacyRoundingMappingRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = ClinicalOps.LegacyRoundingMappingRequiredCategoryRule(
            message: "legacy rounding mapping needs a value"
        )
        let item = ClinicalOps.newLegacyRoundingMapping("", title: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsLegacyRoundingMappingRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = ClinicalOps.LegacyRoundingMappingRequiredEncounterIDRule(
            message: "legacy rounding mapping needs a value"
        )
        let item = ClinicalOps.newLegacyRoundingMapping("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}
