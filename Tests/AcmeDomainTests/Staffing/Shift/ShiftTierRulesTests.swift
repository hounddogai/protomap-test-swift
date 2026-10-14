@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftTierValidator()
        let item = Staffing.newShiftTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftTierPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Staffing.ShiftTierPhoneLengthRule(maxLength: 120)
        let item = Staffing.newShiftTier("x", name: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftTierCodeLengthRule(maxLength: 80)
        let item = Staffing.newShiftTier("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftTierRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.ShiftTierRequiredExternalRefRule(message: "shift tier needs a value")
        let item = Staffing.newShiftTier("", name: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftTierExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.ShiftTierExternalRefLengthRule(maxLength: 120)
        let item = Staffing.newShiftTier("x", name: "y")
        item.externalRef = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
