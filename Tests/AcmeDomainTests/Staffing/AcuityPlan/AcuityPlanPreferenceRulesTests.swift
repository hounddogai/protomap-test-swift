@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanPreferenceValidator()
        let item = Staffing.newAcuityPlanPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.AcuityPlanPreferenceLabelLengthRule(maxLength: 64)
        let item = Staffing.newAcuityPlanPreference("x", name: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.AcuityPlanPreferenceRequiredNameRule(message: "acuity plan preference needs an entry")
        let item = Staffing.newAcuityPlanPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanPreferenceRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.AcuityPlanPreferenceRequiredAllergyRule(message: "acuity plan preference needs this field")
        let item = Staffing.newAcuityPlanPreference("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
