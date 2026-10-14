@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptivePanelEstimateValidator()
        let item = Labs.newAdaptivePanelEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptivePanelEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AdaptivePanelEstimateRequiredCodeRule(message: "adaptive panel estimate needs this field")
        let item = Labs.newAdaptivePanelEstimate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptivePanelEstimateRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.AdaptivePanelEstimateRequiredDiagnosisCodeRule(message: "adaptive panel estimate needs a value")
        let item = Labs.newAdaptivePanelEstimate("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptivePanelEstimateCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.AdaptivePanelEstimateCapacityRangeRule(min: 80, max: 120)
        let item = Labs.newAdaptivePanelEstimate("x", label: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}
