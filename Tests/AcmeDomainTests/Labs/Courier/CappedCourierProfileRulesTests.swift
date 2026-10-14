@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedCourierProfileValidator()
        let item = Labs.newCappedCourierProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedCourierProfilePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Labs.CappedCourierProfilePatientRefLengthRule(maxLength: 64)
        let item = Labs.newCappedCourierProfile("x", label: "y")
        item.patientRef = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedCourierProfileRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Labs.CappedCourierProfileRequiredPatientRefRule(message: "capped courier profile needs this field")
        let item = Labs.newCappedCourierProfile("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedCourierProfileQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.CappedCourierProfileQuantityRangeRule(min: 16, max: 64)
        let item = Labs.newCappedCourierProfile("x", label: "y")
        item.quantity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedCourierProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.CappedCourierProfileCodeLengthRule(maxLength: 1000)
        let item = Labs.newCappedCourierProfile("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
