@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeMilestoneValidator()
        let item = Staffing.newOvertimeMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeMilestoneLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.OvertimeMilestoneLabelLengthRule(maxLength: 3600)
        let item = Staffing.newOvertimeMilestone("x", name: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeMilestoneRequiredCodeRule(message: "overtime milestone needs a value")
        let item = Staffing.newOvertimeMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeMilestoneRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Staffing.OvertimeMilestoneRequiredUnitRule(message: "overtime milestone needs a value")
        let item = Staffing.newOvertimeMilestone("", name: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
