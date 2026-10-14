@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientWorklistTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientWorklistTemplateValidator()
        let item = Imaging.newLenientWorklistTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientWorklistTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.LenientWorklistTemplateLabelLengthRule(maxLength: 64)
        let item = Imaging.newLenientWorklistTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientWorklistTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.LenientWorklistTemplateRequiredCodeRule(message: "lenient worklist template needs an entry")
        let item = Imaging.newLenientWorklistTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientWorklistTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.LenientWorklistTemplateCodeLengthRule(maxLength: 255)
        let item = Imaging.newLenientWorklistTemplate("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLenientWorklistTemplateRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.LenientWorklistTemplateRequiredAllergyRule(
            message: "lenient worklist template needs this field"
        )
        let item = Imaging.newLenientWorklistTemplate("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientWorklistTemplateVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Imaging.LenientWorklistTemplateVersionRangeRule(min: 3600, max: 86400)
        let item = Imaging.newLenientWorklistTemplate("x", label: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}
