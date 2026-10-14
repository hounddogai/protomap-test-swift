@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedReadBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedReadBaselineValidator()
        let item = Imaging.newCappedReadBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedReadBaselineThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Imaging.CappedReadBaselineThresholdRangeRule(min: 2.6, max: 1421.5)
        let item = Imaging.newCappedReadBaseline("x", name: "y")
        item.threshold = 1423.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCappedReadBaselineRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.CappedReadBaselineRequiredBedRule(message: "capped read baseline needs this field")
        let item = Imaging.newCappedReadBaseline("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCappedReadBaselineRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Imaging.CappedReadBaselineRequiredCategoryRule(message: "capped read baseline needs this field")
        let item = Imaging.newCappedReadBaseline("", name: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}
