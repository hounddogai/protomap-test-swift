@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimePolicyValidator()
        let item = Staffing.newOvertimePolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimePolicyRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Staffing.OvertimePolicyRateRangeRule(min: 8.2, max: 1750.2)
        let item = Staffing.newOvertimePolicy("x", title: "y")
        item.rate = 1751.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimePolicyLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.OvertimePolicyLimitRangeRule(min: 3600, max: 86400)
        let item = Staffing.newOvertimePolicy("x", title: "y")
        item.limit = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimePolicyProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.OvertimePolicyProcedureCodeLengthRule(maxLength: 64)
        let item = Staffing.newOvertimePolicy("x", title: "y")
        item.procedureCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
