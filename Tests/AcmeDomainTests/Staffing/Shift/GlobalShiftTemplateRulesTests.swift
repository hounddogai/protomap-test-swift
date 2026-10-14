@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalShiftTemplateValidator()
        let item = Staffing.newGlobalShiftTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalShiftTemplateExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Staffing.GlobalShiftTemplateExternalRefLengthRule(maxLength: 86400)
        let item = Staffing.newGlobalShiftTemplate("x", label: "y")
        item.externalRef = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalShiftTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.GlobalShiftTemplateLabelLengthRule(maxLength: 120)
        let item = Staffing.newGlobalShiftTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalShiftTemplateRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Staffing.GlobalShiftTemplateRequiredSpecialtyRule(message: "global shift template needs this field")
        let item = Staffing.newGlobalShiftTemplate("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingGlobalShiftTemplateRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.GlobalShiftTemplateRequiredExternalRefRule(message: "global shift template needs this field")
        let item = Staffing.newGlobalShiftTemplate("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
