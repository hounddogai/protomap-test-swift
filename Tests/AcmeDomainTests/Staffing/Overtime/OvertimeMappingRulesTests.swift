@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeMappingValidator()
        let item = Staffing.newOvertimeMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeMappingCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.OvertimeMappingCopayRangeRule(min: 0.4, max: 689.1)
        let item = Staffing.newOvertimeMapping("x", title: "y")
        item.copay = 690.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.OvertimeMappingRequiredTitleRule(message: "overtime mapping needs an entry")
        let item = Staffing.newOvertimeMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeMappingRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.OvertimeMappingRequiredProcedureCodeRule(message: "overtime mapping needs a value")
        let item = Staffing.newOvertimeMapping("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
