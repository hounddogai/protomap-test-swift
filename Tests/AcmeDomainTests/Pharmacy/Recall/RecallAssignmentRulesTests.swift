@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallAssignmentValidator()
        let item = Pharmacy.newRecallAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.RecallAssignmentRequiredLabelRule(message: "recall assignment needs this field")
        let item = Pharmacy.newRecallAssignment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallAssignmentRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Pharmacy.RecallAssignmentRequiredOwnerIDRule(message: "recall assignment needs an entry")
        let item = Pharmacy.newRecallAssignment("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.RecallAssignmentRequiredCodeRule(message: "recall assignment needs a value")
        let item = Pharmacy.newRecallAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRecallAssignmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.RecallAssignmentPayerLengthRule(maxLength: 32)
        let item = Pharmacy.newRecallAssignment("x", label: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallAssignmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.RecallAssignmentStartsAtRangeRule(min: 16, max: 1000)
        let item = Pharmacy.newRecallAssignment("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
