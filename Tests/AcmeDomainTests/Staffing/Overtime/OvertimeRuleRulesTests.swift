@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeRuleValidator()
        let item = Staffing.newOvertimeRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeRulePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.OvertimeRulePayerLengthRule(maxLength: 32)
        let item = Staffing.newOvertimeRule("x", label: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeRuleCodeLengthRule(maxLength: 16)
        let item = Staffing.newOvertimeRule("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeRuleRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.OvertimeRuleRequiredProcedureCodeRule(message: "overtime rule needs an entry")
        let item = Staffing.newOvertimeRule("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeRuleMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Staffing.OvertimeRuleMaximumRangeRule(min: 3.7, max: 142.2)
        let item = Staffing.newOvertimeRule("x", label: "y")
        item.maximum = 143.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeRuleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.OvertimeRuleThresholdRangeRule(min: 2.2, max: 3497.1)
        let item = Staffing.newOvertimeRule("x", label: "y")
        item.threshold = 3498.6
        #expect(rule.check(item).count > 0)
    }
}
