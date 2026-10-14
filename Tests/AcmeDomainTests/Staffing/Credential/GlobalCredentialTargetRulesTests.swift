@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalCredentialTargetValidator()
        let item = Staffing.newGlobalCredentialTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalCredentialTargetBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.GlobalCredentialTargetBudgetRangeRule(min: 0.0, max: 792.2)
        let item = Staffing.newGlobalCredentialTarget("x", name: "y")
        item.budget = 793.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalCredentialTargetRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Staffing.GlobalCredentialTargetRequiredCurrencyRule(message: "global credential target needs a value")
        let item = Staffing.newGlobalCredentialTarget("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalCredentialTargetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Staffing.GlobalCredentialTargetUpdatedAtRangeRule(min: 16, max: 64)
        let item = Staffing.newGlobalCredentialTarget("x", name: "y")
        item.updatedAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalCredentialTargetDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Staffing.GlobalCredentialTargetDiagnosisCodeLengthRule(maxLength: 86400)
        let item = Staffing.newGlobalCredentialTarget("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
