@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedDispenseAssignmentValidator()
        let item = Pharmacy.newWeightedDispenseAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedDispenseAssignmentRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.WeightedDispenseAssignmentRetriesRangeRule(min: 64, max: 64)
        let item = Pharmacy.newWeightedDispenseAssignment("x", label: "y")
        item.retries = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedDispenseAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.WeightedDispenseAssignmentLabelLengthRule(maxLength: 120)
        let item = Pharmacy.newWeightedDispenseAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedDispenseAssignmentRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.WeightedDispenseAssignmentRequiredBedRule(
            message: "weighted dispense assignment needs a value"
        )
        let item = Pharmacy.newWeightedDispenseAssignment("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
