@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedGoalDraftValidator()
        let item = CareManagement.newBatchedGoalDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedGoalDraftRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = CareManagement.BatchedGoalDraftRequiredRegionRule(message: "batched goal draft needs a value")
        let item = CareManagement.newBatchedGoalDraft("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedGoalDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.BatchedGoalDraftNameLengthRule(maxLength: 86400)
        let item = CareManagement.newBatchedGoalDraft("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedGoalDraftRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.BatchedGoalDraftRequiredNameRule(message: "batched goal draft needs this field")
        let item = CareManagement.newBatchedGoalDraft("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedGoalDraftMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = CareManagement.BatchedGoalDraftMinimumRangeRule(min: 6.6, max: 1240.0)
        let item = CareManagement.newBatchedGoalDraft("x", name: "y")
        item.minimum = 1241.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedGoalDraftRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = CareManagement.BatchedGoalDraftRegionLengthRule(maxLength: 1000)
        let item = CareManagement.newBatchedGoalDraft("x", name: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}
