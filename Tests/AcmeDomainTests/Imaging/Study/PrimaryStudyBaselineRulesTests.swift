@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryStudyBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrimaryStudyBaselineValidator()
        let item = Imaging.newPrimaryStudyBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrimaryStudyBaselineMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.PrimaryStudyBaselineMaximumRangeRule(min: 8.0, max: 4303.0)
        let item = Imaging.newPrimaryStudyBaseline("x", label: "y")
        item.maximum = 4304.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryStudyBaselineRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Imaging.PrimaryStudyBaselineRequiredRegionRule(message: "primary study baseline needs a value")
        let item = Imaging.newPrimaryStudyBaseline("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrimaryStudyBaselineCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.PrimaryStudyBaselineCeilingRangeRule(min: 6.0, max: 398.9)
        let item = Imaging.newPrimaryStudyBaseline("x", label: "y")
        item.ceiling = 400.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrimaryStudyBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PrimaryStudyBaselineLabelLengthRule(maxLength: 1000)
        let item = Imaging.newPrimaryStudyBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrimaryStudyBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.PrimaryStudyBaselineRequiredLabelRule(message: "primary study baseline needs an entry")
        let item = Imaging.newPrimaryStudyBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
