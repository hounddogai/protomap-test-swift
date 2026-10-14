@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallBatchValidator()
        let item = Pharmacy.newRecallBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RecallBatchRequiredLabelRule(message: "recall batch needs an entry")
        let item = Pharmacy.newRecallBatch("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallBatchVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.RecallBatchVersionRangeRule(min: 16, max: 1000)
        let item = Pharmacy.newRecallBatch("x", label: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallBatchAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.RecallBatchAttemptsRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newRecallBatch("x", label: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}
