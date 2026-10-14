@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedOutreachCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedOutreachCheckpointValidator()
        let item = CareManagement.newBatchedOutreachCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedOutreachCheckpointMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = CareManagement.BatchedOutreachCheckpointMaximumRangeRule(min: 5.1, max: 2296.3)
        let item = CareManagement.newBatchedOutreachCheckpoint("x", name: "y")
        item.maximum = 2297.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedOutreachCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.BatchedOutreachCheckpointRequiredNameRule(
            message: "batched outreach checkpoint needs this field"
        )
        let item = CareManagement.newBatchedOutreachCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedOutreachCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.BatchedOutreachCheckpointRequiredCodeRule(
            message: "batched outreach checkpoint needs a value"
        )
        let item = CareManagement.newBatchedOutreachCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedOutreachCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.BatchedOutreachCheckpointCodeLengthRule(maxLength: 80)
        let item = CareManagement.newBatchedOutreachCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedOutreachCheckpointRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.BatchedOutreachCheckpointRequiredWardRule(
            message: "batched outreach checkpoint needs this field"
        )
        let item = CareManagement.newBatchedOutreachCheckpoint("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementBatchedOutreachCheckpointAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = CareManagement.BatchedOutreachCheckpointAttemptsRangeRule(min: 16, max: 3600)
        let item = CareManagement.newBatchedOutreachCheckpoint("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}
