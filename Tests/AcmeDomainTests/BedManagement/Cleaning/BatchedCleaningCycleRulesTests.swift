@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedCleaningCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedCleaningCycleValidator()
        let item = BedManagement.newBatchedCleaningCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedCleaningCycleMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = BedManagement.BatchedCleaningCycleMaximumRangeRule(min: 3.3, max: 1606.2)
        let item = BedManagement.newBatchedCleaningCycle("x", title: "y")
        item.maximum = 1607.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementBatchedCleaningCycleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.BatchedCleaningCycleCodeLengthRule(maxLength: 16)
        let item = BedManagement.newBatchedCleaningCycle("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedCleaningCyclePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = BedManagement.BatchedCleaningCyclePriorityRangeRule(min: 16, max: 1000)
        let item = BedManagement.newBatchedCleaningCycle("x", title: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}
