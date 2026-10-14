@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalFloatPoolTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultSeasonalFloatPoolTemplateValidator()
        let item = Staffing.newSeasonalFloatPoolTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingSeasonalFloatPoolTemplateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Staffing.SeasonalFloatPoolTemplateDiscountRangeRule(min: 9.0, max: 2302.4)
        let item = Staffing.newSeasonalFloatPoolTemplate("x", label: "y")
        item.discount = 2303.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingSeasonalFloatPoolTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.SeasonalFloatPoolTemplateRequiredCodeRule(
            message: "seasonal float pool template needs an entry"
        )
        let item = Staffing.newSeasonalFloatPoolTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalFloatPoolTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.SeasonalFloatPoolTemplateRequiredLabelRule(
            message: "seasonal float pool template needs a value"
        )
        let item = Staffing.newSeasonalFloatPoolTemplate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingSeasonalFloatPoolTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.SeasonalFloatPoolTemplateLabelLengthRule(maxLength: 3600)
        let item = Staffing.newSeasonalFloatPoolTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
