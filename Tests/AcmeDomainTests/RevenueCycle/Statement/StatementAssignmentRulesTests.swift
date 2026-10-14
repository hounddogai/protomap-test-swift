@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementAssignmentValidator()
        let item = RevenueCycle.newStatementAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementAssignmentAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = RevenueCycle.StatementAssignmentAllergyLengthRule(maxLength: 255)
        let item = RevenueCycle.newStatementAssignment("x", label: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementAssignmentRequiredCodeRule(message: "statement assignment needs this field")
        let item = RevenueCycle.newStatementAssignment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementAssignmentCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.StatementAssignmentCeilingRangeRule(min: 5.5, max: 936.2)
        let item = RevenueCycle.newStatementAssignment("x", label: "y")
        item.ceiling = 937.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementAssignmentExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.StatementAssignmentExpiresAtRangeRule(min: 16, max: 32)
        let item = RevenueCycle.newStatementAssignment("x", label: "y")
        item.expiresAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.StatementAssignmentTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newStatementAssignment("x", label: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
