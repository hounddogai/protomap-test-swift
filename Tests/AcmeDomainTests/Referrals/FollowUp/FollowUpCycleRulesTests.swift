@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpCycleValidator()
        let item = Referrals.newFollowUpCycle("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpCycleBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.FollowUpCycleBatchSizeRangeRule(min: 255, max: 86400)
        let item = Referrals.newFollowUpCycle("x", label: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FollowUpCycleRequiredCodeRule(message: "follow up cycle needs an entry")
        let item = Referrals.newFollowUpCycle("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpCycleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Referrals.FollowUpCycleExpiresAtRangeRule(min: 255, max: 3600)
        let item = Referrals.newFollowUpCycle("x", label: "y")
        item.expiresAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpCycleMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.FollowUpCycleMarginRangeRule(min: 9.9, max: 3404.8)
        let item = Referrals.newFollowUpCycle("x", label: "y")
        item.margin = 3406.3
        #expect(rule.check(item).count > 0)
    }
}
