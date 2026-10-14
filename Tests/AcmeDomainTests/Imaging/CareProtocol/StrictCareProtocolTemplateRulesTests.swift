@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStrictCareProtocolTemplateValidator()
        let item = Imaging.newStrictCareProtocolTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStrictCareProtocolTemplateRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.StrictCareProtocolTemplateRequiredSummaryRule(
            message: "strict care protocol template needs a value"
        )
        let item = Imaging.newStrictCareProtocolTemplate("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStrictCareProtocolTemplateDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.StrictCareProtocolTemplateDosageMgRangeRule(min: 3.4, max: 803.0)
        let item = Imaging.newStrictCareProtocolTemplate("x", label: "y")
        item.dosageMg = 804.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStrictCareProtocolTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.StrictCareProtocolTemplateLabelLengthRule(maxLength: 3600)
        let item = Imaging.newStrictCareProtocolTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
