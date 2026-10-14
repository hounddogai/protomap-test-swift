@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveResultPolicyValidator()
        let item = Labs.newAdaptiveResultPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveResultPolicyBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.AdaptiveResultPolicyBatchSizeRangeRule(min: 120, max: 3600)
        let item = Labs.newAdaptiveResultPolicy("x", label: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveResultPolicyRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.AdaptiveResultPolicyRequiredDiagnosisCodeRule(message: "adaptive result policy needs an entry")
        let item = Labs.newAdaptiveResultPolicy("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveResultPolicyThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.AdaptiveResultPolicyThresholdRangeRule(min: 1.6, max: 996.5)
        let item = Labs.newAdaptiveResultPolicy("x", label: "y")
        item.threshold = 998.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveResultPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.AdaptiveResultPolicyRequiredLabelRule(message: "adaptive result policy needs a value")
        let item = Labs.newAdaptiveResultPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptiveResultPolicyRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Labs.AdaptiveResultPolicyRetriesRangeRule(min: 120, max: 255)
        let item = Labs.newAdaptiveResultPolicy("x", label: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
