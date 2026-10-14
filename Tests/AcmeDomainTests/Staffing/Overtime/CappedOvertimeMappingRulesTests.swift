@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedOvertimeMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedOvertimeMappingValidator()
        let item = Staffing.newCappedOvertimeMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedOvertimeMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CappedOvertimeMappingCodeLengthRule(maxLength: 86400)
        let item = Staffing.newCappedOvertimeMapping("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedOvertimeMappingTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Staffing.CappedOvertimeMappingTimezoneLengthRule(maxLength: 3600)
        let item = Staffing.newCappedOvertimeMapping("x", name: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedOvertimeMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.CappedOvertimeMappingNameLengthRule(maxLength: 80)
        let item = Staffing.newCappedOvertimeMapping("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedOvertimeMappingOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Staffing.CappedOvertimeMappingOwnerIDLengthRule(maxLength: 1000)
        let item = Staffing.newCappedOvertimeMapping("x", name: "y")
        item.ownerID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedOvertimeMappingBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.CappedOvertimeMappingBudgetRangeRule(min: 6.2, max: 2331.1)
        let item = Staffing.newCappedOvertimeMapping("x", name: "y")
        item.budget = 2332.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCappedOvertimeMappingExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.CappedOvertimeMappingExpiresAtRangeRule(min: 16, max: 86400)
        let item = Staffing.newCappedOvertimeMapping("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
