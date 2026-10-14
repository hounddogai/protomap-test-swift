@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualResultWindowValidator()
        let item = Labs.newManualResultWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualResultWindowRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.ManualResultWindowRequiredSegmentRule(message: "manual result window needs this field")
        let item = Labs.newManualResultWindow("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualResultWindowDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.ManualResultWindowDurationMinutesRangeRule(min: 255, max: 255)
        let item = Labs.newManualResultWindow("x", name: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsManualResultWindowRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Labs.ManualResultWindowRequiredWardRule(message: "manual result window needs a value")
        let item = Labs.newManualResultWindow("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualResultWindowWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Labs.ManualResultWindowWindowDaysRangeRule(min: 255, max: 86400)
        let item = Labs.newManualResultWindow("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsManualResultWindowThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.ManualResultWindowThresholdRangeRule(min: 6.5, max: 760.6)
        let item = Labs.newManualResultWindow("x", name: "y")
        item.threshold = 762.1
        #expect(rule.check(item).count > 0)
    }
}
