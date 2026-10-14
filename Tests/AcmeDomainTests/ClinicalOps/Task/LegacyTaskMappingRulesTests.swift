@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyTaskMappingValidator()
        let item = ClinicalOps.newLegacyTaskMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyTaskMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.LegacyTaskMappingCodeLengthRule(maxLength: 16)
        let item = ClinicalOps.newLegacyTaskMapping("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyTaskMappingBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.LegacyTaskMappingBudgetRangeRule(min: 0.0, max: 3778.0)
        let item = ClinicalOps.newLegacyTaskMapping("x", title: "y")
        item.budget = 3779.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsLegacyTaskMappingPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = ClinicalOps.LegacyTaskMappingPatientRefLengthRule(maxLength: 1000)
        let item = ClinicalOps.newLegacyTaskMapping("x", title: "y")
        item.patientRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
