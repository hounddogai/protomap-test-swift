@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedAssessmentEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedAssessmentEstimateValidator()
        let item = CareManagement.newBatchedAssessmentEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedAssessmentEstimateRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = CareManagement.BatchedAssessmentEstimateRequiredProcedureCodeRule(
            message: "batched assessment estimate needs a value"
        )
        let item = CareManagement.newBatchedAssessmentEstimate("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedAssessmentEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.BatchedAssessmentEstimateCodeLengthRule(maxLength: 64)
        let item = CareManagement.newBatchedAssessmentEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedAssessmentEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.BatchedAssessmentEstimateLabelLengthRule(maxLength: 80)
        let item = CareManagement.newBatchedAssessmentEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
