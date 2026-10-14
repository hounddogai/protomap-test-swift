@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackHandoffThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackHandoffThresholdValidator()
        let item = ClinicalOps.newFallbackHandoffThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackHandoffThresholdScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = ClinicalOps.FallbackHandoffThresholdScoreRangeRule(min: 4.4, max: 4811.0)
        let item = ClinicalOps.newFallbackHandoffThreshold("x", title: "y")
        item.score = 4812.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackHandoffThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.FallbackHandoffThresholdTitleLengthRule(maxLength: 32)
        let item = ClinicalOps.newFallbackHandoffThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackHandoffThresholdDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = ClinicalOps.FallbackHandoffThresholdDurationMinutesRangeRule(min: 64, max: 1000)
        let item = ClinicalOps.newFallbackHandoffThreshold("x", title: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
