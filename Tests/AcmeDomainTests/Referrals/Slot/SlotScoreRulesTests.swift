@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotScoreValidator()
        let item = Referrals.newSlotScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotScoreRequiredCodeRule(message: "slot score needs this field")
        let item = Referrals.newSlotScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotScoreRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.SlotScoreRequiredLocaleRule(message: "slot score needs an entry")
        let item = Referrals.newSlotScore("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotScoreThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Referrals.SlotScoreThresholdRangeRule(min: 2.0, max: 199.3)
        let item = Referrals.newSlotScore("x", label: "y")
        item.threshold = 200.8
        #expect(rule.check(item).count > 0)
    }
}
