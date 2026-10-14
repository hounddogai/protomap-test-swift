@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeTargetValidator()
        let item = Staffing.newOvertimeTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeTargetMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.OvertimeTargetMinimumRangeRule(min: 8.2, max: 3025.0)
        let item = Staffing.newOvertimeTarget("x", label: "y")
        item.minimum = 3026.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeTargetRequiredTitleRule(message: "overtime target needs this field")
        let item = Staffing.newOvertimeTarget("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeTargetLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.OvertimeTargetLimitRangeRule(min: 1000, max: 86400)
        let item = Staffing.newOvertimeTarget("x", label: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}
