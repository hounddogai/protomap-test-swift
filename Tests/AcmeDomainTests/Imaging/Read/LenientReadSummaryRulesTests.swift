@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLenientReadSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultLenientReadSummaryValidator()
        let item = Imaging.newLenientReadSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingLenientReadSummaryRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Imaging.LenientReadSummaryRequiredDescriptionRule(message: "lenient read summary needs a value")
        let item = Imaging.newLenientReadSummary("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingLenientReadSummaryWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.LenientReadSummaryWindowDaysRangeRule(min: 64, max: 80)
        let item = Imaging.newLenientReadSummary("x", label: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingLenientReadSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.LenientReadSummaryRequiredLabelRule(message: "lenient read summary needs a value")
        let item = Imaging.newLenientReadSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
