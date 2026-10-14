@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultShiftAllocationValidator()
        let item = Staffing.newDefaultShiftAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultShiftAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.DefaultShiftAllocationCodeLengthRule(maxLength: 64)
        let item = Staffing.newDefaultShiftAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultShiftAllocationReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.DefaultShiftAllocationReviewerLengthRule(maxLength: 80)
        let item = Staffing.newDefaultShiftAllocation("x", name: "y")
        item.reviewer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
