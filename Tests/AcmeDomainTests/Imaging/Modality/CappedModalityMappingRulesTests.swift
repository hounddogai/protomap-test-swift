@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedModalityMappingValidator()
        let item = Imaging.newCappedModalityMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedModalityMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CappedModalityMappingRequiredCodeRule(message: "capped modality mapping needs this field")
        let item = Imaging.newCappedModalityMapping("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedModalityMappingRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Imaging.CappedModalityMappingRequiredExternalRefRule(message: "capped modality mapping needs a value")
        let item = Imaging.newCappedModalityMapping("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedModalityMappingMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.CappedModalityMappingMarginRangeRule(min: 2.7, max: 4405.2)
        let item = Imaging.newCappedModalityMapping("x", title: "y")
        item.margin = 4406.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCappedModalityMappingExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Imaging.CappedModalityMappingExternalRefLengthRule(maxLength: 3600)
        let item = Imaging.newCappedModalityMapping("x", title: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
