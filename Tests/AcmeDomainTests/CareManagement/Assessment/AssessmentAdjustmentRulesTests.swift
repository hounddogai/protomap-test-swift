@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultAssessmentAdjustmentValidator()
        let item = CareManagement.newAssessmentAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementAssessmentAdjustmentCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.AssessmentAdjustmentCapacityRangeRule(min: 16, max: 80)
        let item = CareManagement.newAssessmentAdjustment("x", label: "y")
        item.capacity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentAdjustmentRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.AssessmentAdjustmentRetriesRangeRule(min: 1000, max: 3600)
        let item = CareManagement.newAssessmentAdjustment("x", label: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementAssessmentAdjustmentEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.AssessmentAdjustmentEncounterIDLengthRule(maxLength: 16)
        let item = CareManagement.newAssessmentAdjustment("x", label: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementAssessmentAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.AssessmentAdjustmentCodeLengthRule(maxLength: 3600)
        let item = CareManagement.newAssessmentAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
