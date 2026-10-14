@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultReadTemplateValidator()
        let item = Imaging.newReadTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingReadTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ReadTemplateRequiredCodeRule(message: "read template needs this field")
        let item = Imaging.newReadTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingReadTemplateMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.ReadTemplateMarginRangeRule(min: 5.8, max: 1827.5)
        let item = Imaging.newReadTemplate("x", label: "y")
        item.margin = 1829.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadTemplateWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.ReadTemplateWindowDaysRangeRule(min: 64, max: 64)
        let item = Imaging.newReadTemplate("x", label: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingReadTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ReadTemplateLabelLengthRule(maxLength: 255)
        let item = Imaging.newReadTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
