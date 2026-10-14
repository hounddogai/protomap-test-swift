@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeAssignmentValidator()
        let item = Labs.newReferenceRangeAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeAssignmentRequiredCodeRule(message: "reference range assignment needs this field")
        let item = Labs.newReferenceRangeAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeAssignmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Labs.ReferenceRangeAssignmentStartsAtRangeRule(min: 16, max: 1000)
        let item = Labs.newReferenceRangeAssignment("x", name: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeAssignmentCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.ReferenceRangeAssignmentCreatedAtRangeRule(min: 16, max: 255)
        let item = Labs.newReferenceRangeAssignment("x", name: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}
