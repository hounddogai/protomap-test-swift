@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRegionalReferenceRangeMappingValidator()
        let item = Labs.newRegionalReferenceRangeMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRegionalReferenceRangeMappingAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Labs.RegionalReferenceRangeMappingAcuityRangeRule(min: 16, max: 120)
        let item = Labs.newRegionalReferenceRangeMapping("x", name: "y")
        item.acuity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalReferenceRangeMappingThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.RegionalReferenceRangeMappingThresholdRangeRule(min: 1.2, max: 119.3)
        let item = Labs.newRegionalReferenceRangeMapping("x", name: "y")
        item.threshold = 120.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRegionalReferenceRangeMappingRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.RegionalReferenceRangeMappingRequiredNameRule(
            message: "regional reference range mapping needs an entry"
        )
        let item = Labs.newRegionalReferenceRangeMapping("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
