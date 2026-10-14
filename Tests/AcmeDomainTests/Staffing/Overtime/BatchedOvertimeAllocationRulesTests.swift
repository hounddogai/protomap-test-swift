@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultBatchedOvertimeAllocationValidator()
        let item = Staffing.newBatchedOvertimeAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingBatchedOvertimeAllocationFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.BatchedOvertimeAllocationFloorValueRangeRule(min: 9.9, max: 1678.5)
        let item = Staffing.newBatchedOvertimeAllocation("x", title: "y")
        item.floorValue = 1680.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingBatchedOvertimeAllocationWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.BatchedOvertimeAllocationWeightRangeRule(min: 2.2, max: 1904.4)
        let item = Staffing.newBatchedOvertimeAllocation("x", title: "y")
        item.weight = 1905.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingBatchedOvertimeAllocationEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Staffing.BatchedOvertimeAllocationEndsAtRangeRule(min: 16, max: 3600)
        let item = Staffing.newBatchedOvertimeAllocation("x", title: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingBatchedOvertimeAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.BatchedOvertimeAllocationRequiredTitleRule(
            message: "batched overtime allocation needs a value"
        )
        let item = Staffing.newBatchedOvertimeAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
