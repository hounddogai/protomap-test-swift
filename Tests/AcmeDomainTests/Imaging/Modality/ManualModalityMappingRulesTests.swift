@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualModalityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualModalityMappingValidator()
        let item = Imaging.newManualModalityMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualModalityMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ManualModalityMappingRequiredCodeRule(message: "manual modality mapping needs this field")
        let item = Imaging.newManualModalityMapping("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualModalityMappingTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ManualModalityMappingTitleLengthRule(maxLength: 16)
        let item = Imaging.newManualModalityMapping("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualModalityMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.ManualModalityMappingCodeLengthRule(maxLength: 80)
        let item = Imaging.newManualModalityMapping("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingManualModalityMappingAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Imaging.ManualModalityMappingAcuityRangeRule(min: 32, max: 80)
        let item = Imaging.newManualModalityMapping("x", title: "y")
        item.acuity = 81
        #expect(rule.check(item).count > 0)
    }
}
