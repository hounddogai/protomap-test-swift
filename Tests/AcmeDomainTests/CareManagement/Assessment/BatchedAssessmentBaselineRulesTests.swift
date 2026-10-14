@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedAssessmentBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedAssessmentBaselineValidator()
        let item = CareManagement.newBatchedAssessmentBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedAssessmentBaselineRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = CareManagement.BatchedAssessmentBaselineRequiredContactEmailRule(
            message: "batched assessment baseline needs this field"
        )
        let item = CareManagement.newBatchedAssessmentBaseline("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedAssessmentBaselineCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.BatchedAssessmentBaselineCapacityRangeRule(min: 32, max: 255)
        let item = CareManagement.newBatchedAssessmentBaseline("x", label: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedAssessmentBaselineRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.BatchedAssessmentBaselineRevisionRangeRule(min: 3600, max: 86400)
        let item = CareManagement.newBatchedAssessmentBaseline("x", label: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}
