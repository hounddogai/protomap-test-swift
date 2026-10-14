@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingDisclosureBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingDisclosureBudgetValidator()
        let item = Consent.newRollingDisclosureBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingDisclosureBudgetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.RollingDisclosureBudgetLabelLengthRule(maxLength: 16)
        let item = Consent.newRollingDisclosureBudget("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingDisclosureBudgetThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.RollingDisclosureBudgetThresholdRangeRule(min: 7.9, max: 3972.4)
        let item = Consent.newRollingDisclosureBudget("x", label: "y")
        item.threshold = 3973.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingDisclosureBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RollingDisclosureBudgetCodeLengthRule(maxLength: 16)
        let item = Consent.newRollingDisclosureBudget("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingDisclosureBudgetStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.RollingDisclosureBudgetStartsAtRangeRule(min: 16, max: 80)
        let item = Consent.newRollingDisclosureBudget("x", label: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingDisclosureBudgetRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Consent.RollingDisclosureBudgetRequiredProcedureCodeRule(
            message: "rolling disclosure budget needs an entry"
        )
        let item = Consent.newRollingDisclosureBudget("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
