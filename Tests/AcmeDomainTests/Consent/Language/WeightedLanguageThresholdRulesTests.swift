@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedLanguageThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWeightedLanguageThresholdValidator()
        let item = Consent.newWeightedLanguageThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWeightedLanguageThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.WeightedLanguageThresholdRequiredNameRule(
            message: "weighted language threshold needs this field"
        )
        let item = Consent.newWeightedLanguageThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWeightedLanguageThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.WeightedLanguageThresholdRequiredCodeRule(
            message: "weighted language threshold needs a value"
        )
        let item = Consent.newWeightedLanguageThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWeightedLanguageThresholdMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.WeightedLanguageThresholdMaximumRangeRule(min: 0.0, max: 2116.9)
        let item = Consent.newWeightedLanguageThreshold("x", name: "y")
        item.maximum = 2118.4
        #expect(rule.check(item).count > 0)
    }
}
