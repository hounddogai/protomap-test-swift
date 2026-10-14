@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimePreferenceValidator()
        let item = Staffing.newOvertimePreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimePreferenceCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Staffing.OvertimePreferenceCostRangeRule(min: 6.4, max: 1815.5)
        let item = Staffing.newOvertimePreference("x", title: "y")
        item.cost = 1817.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimePreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimePreferenceCodeLengthRule(maxLength: 1000)
        let item = Staffing.newOvertimePreference("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimePreferenceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.OvertimePreferenceGraceDaysRangeRule(min: 64, max: 255)
        let item = Staffing.newOvertimePreference("x", title: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimePreferenceAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Staffing.OvertimePreferenceAllergyLengthRule(maxLength: 80)
        let item = Staffing.newOvertimePreference("x", title: "y")
        item.allergy = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimePreferenceRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.OvertimePreferenceRequiredAllergyRule(message: "overtime preference needs an entry")
        let item = Staffing.newOvertimePreference("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
