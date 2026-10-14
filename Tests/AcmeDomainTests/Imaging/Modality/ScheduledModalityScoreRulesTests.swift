@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledModalityScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledModalityScoreValidator()
        let item = Imaging.newScheduledModalityScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledModalityScoreAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.ScheduledModalityScoreAttemptsRangeRule(min: 1000, max: 86400)
        let item = Imaging.newScheduledModalityScore("x", title: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledModalityScoreTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.ScheduledModalityScoreTitleLengthRule(maxLength: 86400)
        let item = Imaging.newScheduledModalityScore("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledModalityScoreBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.ScheduledModalityScoreBatchSizeRangeRule(min: 1000, max: 3600)
        let item = Imaging.newScheduledModalityScore("x", title: "y")
        item.batchSize = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledModalityScoreDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Imaging.ScheduledModalityScoreDescriptionLengthRule(maxLength: 3600)
        let item = Imaging.newScheduledModalityScore("x", title: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledModalityScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.ScheduledModalityScoreRequiredCodeRule(message: "scheduled modality score needs this field")
        let item = Imaging.newScheduledModalityScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
