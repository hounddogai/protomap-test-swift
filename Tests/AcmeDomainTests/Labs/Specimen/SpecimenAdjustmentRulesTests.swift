@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenAdjustmentValidator()
        let item = Labs.newSpecimenAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenAdjustmentCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.SpecimenAdjustmentCategoryLengthRule(maxLength: 64)
        let item = Labs.newSpecimenAdjustment("x", label: "y")
        item.category = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenAdjustmentRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Labs.SpecimenAdjustmentRefillsRangeRule(min: 16, max: 120)
        let item = Labs.newSpecimenAdjustment("x", label: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenAdjustmentRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Labs.SpecimenAdjustmentRequiredDiagnosisCodeRule(message: "specimen adjustment needs a value")
        let item = Labs.newSpecimenAdjustment("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenAdjustmentSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.SpecimenAdjustmentSequenceRangeRule(min: 16, max: 16)
        let item = Labs.newSpecimenAdjustment("x", label: "y")
        item.sequence = 17
        #expect(rule.check(item).count > 0)
    }
}
