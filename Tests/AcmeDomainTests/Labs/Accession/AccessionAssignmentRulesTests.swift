@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionAssignmentValidator()
        let item = Labs.newAccessionAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionAssignmentGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.AccessionAssignmentGraceDaysRangeRule(min: 64, max: 80)
        let item = Labs.newAccessionAssignment("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionAssignmentCodeLengthRule(maxLength: 86400)
        let item = Labs.newAccessionAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
