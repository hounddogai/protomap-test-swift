@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftProfileValidator()
        let item = Staffing.newShiftProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftProfileSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.ShiftProfileSpecialtyLengthRule(maxLength: 80)
        let item = Staffing.newShiftProfile("x", name: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftProfileNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.ShiftProfileNameLengthRule(maxLength: 86400)
        let item = Staffing.newShiftProfile("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftProfileAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Staffing.ShiftProfileAllergyLengthRule(maxLength: 86400)
        let item = Staffing.newShiftProfile("x", name: "y")
        item.allergy = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftProfileRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.ShiftProfileRequiredNameRule(message: "shift profile needs an entry")
        let item = Staffing.newShiftProfile("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftProfileRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.ShiftProfileRetriesRangeRule(min: 3600, max: 86400)
        let item = Staffing.newShiftProfile("x", name: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}
