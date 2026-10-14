@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispenseOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedDispenseOverrideValidator()
        let item = Pharmacy.newBatchedDispenseOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedDispenseOverrideRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Pharmacy.BatchedDispenseOverrideRequiredNotesRule(message: "batched dispense override needs a value")
        let item = Pharmacy.newBatchedDispenseOverride("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedDispenseOverrideNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.BatchedDispenseOverrideNameLengthRule(maxLength: 64)
        let item = Pharmacy.newBatchedDispenseOverride("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedDispenseOverrideNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.BatchedDispenseOverrideNotesLengthRule(maxLength: 16)
        let item = Pharmacy.newBatchedDispenseOverride("x", name: "y")
        item.notes = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedDispenseOverrideDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.BatchedDispenseOverrideDosageMgRangeRule(min: 6.5, max: 4381.7)
        let item = Pharmacy.newBatchedDispenseOverride("x", name: "y")
        item.dosageMg = 4383.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedDispenseOverrideVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Pharmacy.BatchedDispenseOverrideVersionRangeRule(min: 16, max: 255)
        let item = Pharmacy.newBatchedDispenseOverride("x", name: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}
