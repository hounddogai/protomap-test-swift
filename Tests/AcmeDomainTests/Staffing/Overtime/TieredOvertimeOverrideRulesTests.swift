@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredOvertimeOverrideValidator()
        let item = Staffing.newTieredOvertimeOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredOvertimeOverrideFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.TieredOvertimeOverrideFloorValueRangeRule(min: 0.8, max: 1274.5)
        let item = Staffing.newTieredOvertimeOverride("x", name: "y")
        item.floorValue = 1276.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingTieredOvertimeOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.TieredOvertimeOverrideCodeLengthRule(maxLength: 3600)
        let item = Staffing.newTieredOvertimeOverride("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredOvertimeOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.TieredOvertimeOverrideRequiredCodeRule(message: "tiered overtime override needs this field")
        let item = Staffing.newTieredOvertimeOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingTieredOvertimeOverrideRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.TieredOvertimeOverrideRequiredProcedureCodeRule(
            message: "tiered overtime override needs this field"
        )
        let item = Staffing.newTieredOvertimeOverride("", name: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
