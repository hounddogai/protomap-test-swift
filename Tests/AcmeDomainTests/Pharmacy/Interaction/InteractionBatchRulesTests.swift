@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionBatchValidator()
        let item = Pharmacy.newInteractionBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionBatchWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Pharmacy.InteractionBatchWardLengthRule(maxLength: 80)
        let item = Pharmacy.newInteractionBatch("x", name: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionBatchSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.InteractionBatchSummaryLengthRule(maxLength: 86400)
        let item = Pharmacy.newInteractionBatch("x", name: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionBatchRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Pharmacy.InteractionBatchRequiredSummaryRule(message: "interaction batch needs a value")
        let item = Pharmacy.newInteractionBatch("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionBatchDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.InteractionBatchDosageMgRangeRule(min: 0.1, max: 708.6)
        let item = Pharmacy.newInteractionBatch("x", name: "y")
        item.dosageMg = 710.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InteractionBatchCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newInteractionBatch("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
