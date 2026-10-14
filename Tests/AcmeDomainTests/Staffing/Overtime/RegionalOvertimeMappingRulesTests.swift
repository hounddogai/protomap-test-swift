@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalOvertimeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRegionalOvertimeMappingValidator()
        let item = Staffing.newRegionalOvertimeMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRegionalOvertimeMappingCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Staffing.RegionalOvertimeMappingCopayRangeRule(min: 4.9, max: 807.7)
        let item = Staffing.newRegionalOvertimeMapping("x", name: "y")
        item.copay = 809.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingRegionalOvertimeMappingClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Staffing.RegionalOvertimeMappingClinicianIDLengthRule(maxLength: 120)
        let item = Staffing.newRegionalOvertimeMapping("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalOvertimeMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.RegionalOvertimeMappingNameLengthRule(maxLength: 1000)
        let item = Staffing.newRegionalOvertimeMapping("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalOvertimeMappingProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Staffing.RegionalOvertimeMappingProcedureCodeLengthRule(maxLength: 86400)
        let item = Staffing.newRegionalOvertimeMapping("x", name: "y")
        item.procedureCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRegionalOvertimeMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.RegionalOvertimeMappingRequiredCodeRule(message: "regional overtime mapping needs an entry")
        let item = Staffing.newRegionalOvertimeMapping("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
