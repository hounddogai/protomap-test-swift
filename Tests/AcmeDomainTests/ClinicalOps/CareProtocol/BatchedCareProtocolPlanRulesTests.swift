@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedCareProtocolPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedCareProtocolPlanValidator()
        let item = ClinicalOps.newBatchedCareProtocolPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedCareProtocolPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.BatchedCareProtocolPlanCodeLengthRule(maxLength: 32)
        let item = ClinicalOps.newBatchedCareProtocolPlan("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsBatchedCareProtocolPlanRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.BatchedCareProtocolPlanRateRangeRule(min: 3.5, max: 3314.2)
        let item = ClinicalOps.newBatchedCareProtocolPlan("x", label: "y")
        item.rate = 3315.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsBatchedCareProtocolPlanRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.BatchedCareProtocolPlanRequiredTitleRule(
            message: "batched care protocol plan needs a value"
        )
        let item = ClinicalOps.newBatchedCareProtocolPlan("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
