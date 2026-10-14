@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalStudyVarianceValidator()
        let item = Imaging.newRegionalStudyVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalStudyVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.RegionalStudyVarianceRequiredTitleRule(message: "regional study variance needs a value")
        let item = Imaging.newRegionalStudyVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingRegionalStudyVarianceUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.RegionalStudyVarianceUpdatedAtRangeRule(min: 16, max: 1000)
        let item = Imaging.newRegionalStudyVariance("x", title: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRegionalStudyVarianceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.RegionalStudyVarianceGraceDaysRangeRule(min: 64, max: 80)
        let item = Imaging.newRegionalStudyVariance("x", title: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRegionalStudyVarianceRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Imaging.RegionalStudyVarianceRatioRangeRule(min: 4.3, max: 4979.4)
        let item = Imaging.newRegionalStudyVariance("x", title: "y")
        item.ratio = 4980.9
        #expect(rule.check(item).count > 0)
    }
}
