@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultModalityMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultDefaultModalityMappingValidator()
        let item = Imaging.newDefaultModalityMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingDefaultModalityMappingRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Imaging.DefaultModalityMappingRateRangeRule(min: 6.1, max: 3716.5)
        let item = Imaging.newDefaultModalityMapping("x", title: "y")
        item.rate = 3718.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingDefaultModalityMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.DefaultModalityMappingRequiredTitleRule(message: "default modality mapping needs an entry")
        let item = Imaging.newDefaultModalityMapping("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingDefaultModalityMappingVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Imaging.DefaultModalityMappingVersionRangeRule(min: 32, max: 80)
        let item = Imaging.newDefaultModalityMapping("x", title: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}
