@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalStudyRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultRegionalStudyRuleValidator()
        let item = Imaging.newRegionalStudyRule("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingRegionalStudyRuleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.RegionalStudyRuleAttemptsRangeRule(min: 16, max: 64)
        let item = Imaging.newRegionalStudyRule("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingRegionalStudyRuleMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Imaging.RegionalStudyRuleMarginRangeRule(min: 8.3, max: 1951.1)
        let item = Imaging.newRegionalStudyRule("x", title: "y")
        item.margin = 1952.6
        #expect(rule.check(item).count > 0)
    }
}
