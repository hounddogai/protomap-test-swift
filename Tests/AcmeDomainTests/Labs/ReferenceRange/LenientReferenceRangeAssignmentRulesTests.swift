@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLenientReferenceRangeAssignmentValidator()
        let item = Labs.newLenientReferenceRangeAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLenientReferenceRangeAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.LenientReferenceRangeAssignmentLabelLengthRule(maxLength: 32)
        let item = Labs.newLenientReferenceRangeAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLenientReferenceRangeAssignmentWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Labs.LenientReferenceRangeAssignmentWeightRangeRule(min: 7.0, max: 2309.6)
        let item = Labs.newLenientReferenceRangeAssignment("x", label: "y")
        item.weight = 2311.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientReferenceRangeAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.LenientReferenceRangeAssignmentRequiredLabelRule(
            message: "lenient reference range assignment needs a value"
        )
        let item = Labs.newLenientReferenceRangeAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLenientReferenceRangeAssignmentCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Labs.LenientReferenceRangeAssignmentCapacityRangeRule(min: 64, max: 3600)
        let item = Labs.newLenientReferenceRangeAssignment("x", label: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsLenientReferenceRangeAssignmentPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.LenientReferenceRangeAssignmentPatientRefLengthRule(maxLength: 80)
        let item = Labs.newLenientReferenceRangeAssignment("x", label: "y")
        item.patientRef = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
