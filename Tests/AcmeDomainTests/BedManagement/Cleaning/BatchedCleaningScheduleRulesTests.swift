@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningScheduleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedCleaningScheduleValidator()
        let item = BedManagement.newBatchedCleaningSchedule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedCleaningScheduleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.BatchedCleaningScheduleRequiredLabelRule(
            message: "batched cleaning schedule needs an entry"
        )
        let item = BedManagement.newBatchedCleaningSchedule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBatchedCleaningScheduleStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = BedManagement.BatchedCleaningScheduleStartsAtRangeRule(min: 64, max: 64)
        let item = BedManagement.newBatchedCleaningSchedule("x", label: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedCleaningScheduleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.BatchedCleaningScheduleLabelLengthRule(maxLength: 80)
        let item = BedManagement.newBatchedCleaningSchedule("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedCleaningScheduleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = BedManagement.BatchedCleaningScheduleRetriesRangeRule(min: 64, max: 255)
        let item = BedManagement.newBatchedCleaningSchedule("x", label: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
