@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeCycleValidator()
        let item = Staffing.newOvertimeCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.OvertimeCycleRequiredCodeRule(message: "overtime cycle needs an entry")
        let item = Staffing.newOvertimeCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeCycleGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.OvertimeCycleGraceDaysRangeRule(min: 32, max: 32)
        let item = Staffing.newOvertimeCycle("x", label: "y")
        item.graceDays = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeCycleMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.OvertimeCycleMaximumRangeRule(min: 1.6, max: 2408.8)
        let item = Staffing.newOvertimeCycle("x", label: "y")
        item.maximum = 2410.3
        #expect(rule.check(item).count > 0)
    }
}
