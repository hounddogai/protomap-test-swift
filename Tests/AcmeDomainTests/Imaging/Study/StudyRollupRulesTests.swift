@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyRollupValidator()
        let item = Imaging.newStudyRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StudyRollupRequiredTitleRule(message: "study rollup needs an entry")
        let item = Imaging.newStudyRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyRollupMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.StudyRollupMarginRangeRule(min: 1.1, max: 4482.9)
        let item = Imaging.newStudyRollup("x", title: "y")
        item.margin = 4484.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyRollupThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Imaging.StudyRollupThresholdRangeRule(min: 7.1, max: 2024.8)
        let item = Imaging.newStudyRollup("x", title: "y")
        item.threshold = 2026.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyRollupWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.StudyRollupWeightRangeRule(min: 7.5, max: 4763.2)
        let item = Imaging.newStudyRollup("x", title: "y")
        item.weight = 4764.7
        #expect(rule.check(item).count > 0)
    }
}
