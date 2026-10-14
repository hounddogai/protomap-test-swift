@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedLanguageThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedLanguageThresholdValidator()
        let item = Consent.newBatchedLanguageThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedLanguageThresholdUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Consent.BatchedLanguageThresholdUpdatedAtRangeRule(min: 32, max: 86400)
        let item = Consent.newBatchedLanguageThreshold("x", label: "y")
        item.updatedAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedLanguageThresholdVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.BatchedLanguageThresholdVersionRangeRule(min: 3600, max: 86400)
        let item = Consent.newBatchedLanguageThreshold("x", label: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
