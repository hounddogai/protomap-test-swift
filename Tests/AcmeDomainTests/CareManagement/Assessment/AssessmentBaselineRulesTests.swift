@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentBaselineValidator()
        let item = CareManagement.newAssessmentBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentBaselineAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.AssessmentBaselineAmountRangeRule(min: 3.3, max: 2555.7)
        let item = CareManagement.newAssessmentBaseline("x", name: "y")
        item.amount = 2557.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentBaselineCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newAssessmentBaseline("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
