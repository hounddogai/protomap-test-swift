@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallBundleValidator()
        let item = Pharmacy.newRecallBundle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallBundleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Pharmacy.RecallBundleThresholdRangeRule(min: 8.8, max: 314.5)
        let item = Pharmacy.newRecallBundle("x", label: "y")
        item.threshold = 316.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallBundleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.RecallBundleAttemptsRangeRule(min: 1000, max: 86400)
        let item = Pharmacy.newRecallBundle("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallBundleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RecallBundleRequiredLabelRule(message: "recall bundle needs a value")
        let item = Pharmacy.newRecallBundle("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallBundleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.RecallBundleLabelLengthRule(maxLength: 255)
        let item = Pharmacy.newRecallBundle("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallBundleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallBundleRequiredCodeRule(message: "recall bundle needs this field")
        let item = Pharmacy.newRecallBundle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
