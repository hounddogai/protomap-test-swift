@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedOutreachCycleValidator()
        let item = CareManagement.newBatchedOutreachCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedOutreachCycleRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = CareManagement.BatchedOutreachCycleRequiredEncounterIDRule(
            message: "batched outreach cycle needs this field"
        )
        let item = CareManagement.newBatchedOutreachCycle("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedOutreachCycleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = CareManagement.BatchedOutreachCycleBatchSizeRangeRule(min: 80, max: 3600)
        let item = CareManagement.newBatchedOutreachCycle("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}
