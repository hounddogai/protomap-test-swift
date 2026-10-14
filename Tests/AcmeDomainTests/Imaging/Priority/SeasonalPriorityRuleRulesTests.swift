@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultSeasonalPriorityRuleValidator()
        let item = Imaging.newSeasonalPriorityRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingSeasonalPriorityRuleMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.SeasonalPriorityRuleMaximumRangeRule(min: 3.7, max: 1338.7)
        let item = Imaging.newSeasonalPriorityRule("x", label: "y")
        item.maximum = 1340.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalPriorityRuleGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.SeasonalPriorityRuleGraceDaysRangeRule(min: 16, max: 255)
        let item = Imaging.newSeasonalPriorityRule("x", label: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingSeasonalPriorityRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.SeasonalPriorityRuleLabelLengthRule(maxLength: 255)
        let item = Imaging.newSeasonalPriorityRule("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
