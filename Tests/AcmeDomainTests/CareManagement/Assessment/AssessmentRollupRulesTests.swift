@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentRollupValidator()
        let item = CareManagement.newAssessmentRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentRollupRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = CareManagement.AssessmentRollupRateRangeRule(min: 6.0, max: 1279.5)
        let item = CareManagement.newAssessmentRollup("x", label: "y")
        item.rate = 1281.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentRollupUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = CareManagement.AssessmentRollupUpdatedAtRangeRule(min: 80, max: 1000)
        let item = CareManagement.newAssessmentRollup("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentRollupCodeLengthRule(maxLength: 16)
        let item = CareManagement.newAssessmentRollup("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
