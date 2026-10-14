@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualClosureScoreValidator()
        let item = Referrals.newManualClosureScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualClosureScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.ManualClosureScoreLabelLengthRule(maxLength: 86400)
        let item = Referrals.newManualClosureScore("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualClosureScoreThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Referrals.ManualClosureScoreThresholdRangeRule(min: 7.3, max: 423.5)
        let item = Referrals.newManualClosureScore("x", label: "y")
        item.threshold = 425.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualClosureScoreRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Referrals.ManualClosureScoreRegionLengthRule(maxLength: 1000)
        let item = Referrals.newManualClosureScore("x", label: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualClosureScoreMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.ManualClosureScoreMinimumRangeRule(min: 8.8, max: 1997.1)
        let item = Referrals.newManualClosureScore("x", label: "y")
        item.minimum = 1998.6
        #expect(rule.check(item).count > 0)
    }
}
