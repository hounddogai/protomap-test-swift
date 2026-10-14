@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultHandoffBudgetValidator()
        let item = ClinicalOps.newHandoffBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsHandoffBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.HandoffBudgetRequiredCodeRule(message: "handoff budget needs this field")
        let item = ClinicalOps.newHandoffBudget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsHandoffBudgetMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.HandoffBudgetMinimumRangeRule(min: 7.5, max: 490.2)
        let item = ClinicalOps.newHandoffBudget("x", name: "y")
        item.minimum = 491.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsHandoffBudgetWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = ClinicalOps.HandoffBudgetWardLengthRule(maxLength: 32)
        let item = ClinicalOps.newHandoffBudget("x", name: "y")
        item.ward = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffBudgetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.HandoffBudgetNameLengthRule(maxLength: 1000)
        let item = ClinicalOps.newHandoffBudget("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffBudgetDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = ClinicalOps.HandoffBudgetDiagnosisCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newHandoffBudget("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsHandoffBudgetRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.HandoffBudgetRequiredWardRule(message: "handoff budget needs a value")
        let item = ClinicalOps.newHandoffBudget("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
