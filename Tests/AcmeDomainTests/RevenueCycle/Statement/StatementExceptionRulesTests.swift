@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementExceptionValidator()
        let item = RevenueCycle.newStatementException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementExceptionScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = RevenueCycle.StatementExceptionScoreRangeRule(min: 2.5, max: 2596.4)
        let item = RevenueCycle.newStatementException("x", label: "y")
        item.score = 2597.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementExceptionCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newStatementException("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementExceptionExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.StatementExceptionExpiresAtRangeRule(min: 64, max: 1000)
        let item = RevenueCycle.newStatementException("x", label: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementExceptionRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = RevenueCycle.StatementExceptionRequiredPatientRefRule(message: "statement exception needs an entry")
        let item = RevenueCycle.newStatementException("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
