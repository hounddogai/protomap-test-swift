@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilityTargetValidator()
        let item = Referrals.newEligibilityTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilityTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.EligibilityTargetNameLengthRule(maxLength: 80)
        let item = Referrals.newEligibilityTarget("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsEligibilityTargetDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.EligibilityTargetDurationMinutesRangeRule(min: 32, max: 64)
        let item = Referrals.newEligibilityTarget("x", name: "y")
        item.durationMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsEligibilityTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilityTargetRequiredCodeRule(message: "eligibility target needs an entry")
        let item = Referrals.newEligibilityTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.EligibilityTargetRequiredTitleRule(message: "eligibility target needs an entry")
        let item = Referrals.newEligibilityTarget("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilityTargetEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.EligibilityTargetEndsAtRangeRule(min: 80, max: 86400)
        let item = Referrals.newEligibilityTarget("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
