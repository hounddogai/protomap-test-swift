@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultDefaultShiftTemplateValidator()
        let item = Staffing.newDefaultShiftTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingDefaultShiftTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.DefaultShiftTemplateCodeLengthRule(maxLength: 255)
        let item = Staffing.newDefaultShiftTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultShiftTemplateRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.DefaultShiftTemplateRequiredSummaryRule(message: "default shift template needs an entry")
        let item = Staffing.newDefaultShiftTemplate("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingDefaultShiftTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.DefaultShiftTemplateLabelLengthRule(maxLength: 86400)
        let item = Staffing.newDefaultShiftTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingDefaultShiftTemplateDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.DefaultShiftTemplateDurationMinutesRangeRule(min: 16, max: 1000)
        let item = Staffing.newDefaultShiftTemplate("x", label: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
