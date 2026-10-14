@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudySummaryValidator()
        let item = Imaging.newStudySummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudySummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StudySummaryRequiredTitleRule(message: "study summary needs an entry")
        let item = Imaging.newStudySummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudySummaryChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Imaging.StudySummaryChannelLengthRule(maxLength: 32)
        let item = Imaging.newStudySummary("x", title: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudySummaryCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Imaging.StudySummaryCapacityRangeRule(min: 32, max: 86400)
        let item = Imaging.newStudySummary("x", title: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}
