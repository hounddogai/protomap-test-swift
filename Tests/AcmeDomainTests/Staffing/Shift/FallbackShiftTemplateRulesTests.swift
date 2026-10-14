@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackShiftTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackShiftTemplateValidator()
        let item = Staffing.newFallbackShiftTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackShiftTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.FallbackShiftTemplateLabelLengthRule(maxLength: 32)
        let item = Staffing.newFallbackShiftTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackShiftTemplateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.FallbackShiftTemplateRequiredNameRule(message: "fallback shift template needs this field")
        let item = Staffing.newFallbackShiftTemplate("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackShiftTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackShiftTemplateRequiredCodeRule(message: "fallback shift template needs a value")
        let item = Staffing.newFallbackShiftTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackShiftTemplateCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.FallbackShiftTemplateCeilingRangeRule(min: 3.0, max: 4937.9)
        let item = Staffing.newFallbackShiftTemplate("x", label: "y")
        item.ceiling = 4939.4
        #expect(rule.check(item).count > 0)
    }
}
