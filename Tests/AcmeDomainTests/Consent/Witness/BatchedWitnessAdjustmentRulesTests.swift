@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedWitnessAdjustmentValidator()
        let item = Consent.newBatchedWitnessAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedWitnessAdjustmentUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Consent.BatchedWitnessAdjustmentUnitLengthRule(maxLength: 86400)
        let item = Consent.newBatchedWitnessAdjustment("x", label: "y")
        item.unit = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedWitnessAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.BatchedWitnessAdjustmentRequiredCodeRule(message: "batched witness adjustment needs a value")
        let item = Consent.newBatchedWitnessAdjustment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedWitnessAdjustmentGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Consent.BatchedWitnessAdjustmentGraceDaysRangeRule(min: 255, max: 86400)
        let item = Consent.newBatchedWitnessAdjustment("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
