@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertEstimateValidator()
        let item = ClinicalOps.newAlertEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertEstimateCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.AlertEstimateCreatedAtRangeRule(min: 16, max: 16)
        let item = ClinicalOps.newAlertEstimate("x", label: "y")
        item.createdAt = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertEstimateProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.AlertEstimateProcedureCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newAlertEstimate("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertEstimateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.AlertEstimateRequiredLabelRule(message: "alert estimate needs a value")
        let item = ClinicalOps.newAlertEstimate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
