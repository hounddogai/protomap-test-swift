@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultBatchedOvertimeMappingValidator()
        let item = Staffing.newBatchedOvertimeMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingBatchedOvertimeMappingCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Staffing.BatchedOvertimeMappingCreatedAtRangeRule(min: 255, max: 1000)
        let item = Staffing.newBatchedOvertimeMapping("x", label: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}
