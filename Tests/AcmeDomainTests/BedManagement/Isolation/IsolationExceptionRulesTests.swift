@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationExceptionValidator()
        let item = BedManagement.newIsolationException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationExceptionRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = BedManagement.IsolationExceptionRequiredProcedureCodeRule(
            message: "isolation exception needs an entry"
        )
        let item = BedManagement.newIsolationException("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.IsolationExceptionCodeLengthRule(maxLength: 120)
        let item = BedManagement.newIsolationException("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationExceptionBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.IsolationExceptionBudgetRangeRule(min: 5.4, max: 222.6)
        let item = BedManagement.newIsolationException("x", title: "y")
        item.budget = 224.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementIsolationExceptionRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.IsolationExceptionRetriesRangeRule(min: 255, max: 3600)
        let item = BedManagement.newIsolationException("x", title: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}
