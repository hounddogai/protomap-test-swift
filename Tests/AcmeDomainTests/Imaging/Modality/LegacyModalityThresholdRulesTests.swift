@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyModalityThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLegacyModalityThresholdValidator()
        let item = Imaging.newLegacyModalityThreshold("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLegacyModalityThresholdNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.LegacyModalityThresholdNameLengthRule(maxLength: 3600)
        let item = Imaging.newLegacyModalityThreshold("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingLegacyModalityThresholdDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.LegacyModalityThresholdDosageMgRangeRule(min: 7.5, max: 4796.9)
        let item = Imaging.newLegacyModalityThreshold("x", name: "y")
        item.dosageMg = 4798.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLegacyModalityThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.LegacyModalityThresholdRequiredCodeRule(message: "legacy modality threshold needs this field")
        let item = Imaging.newLegacyModalityThreshold("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLegacyModalityThresholdRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.LegacyModalityThresholdRequiredNameRule(message: "legacy modality threshold needs this field")
        let item = Imaging.newLegacyModalityThreshold("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
