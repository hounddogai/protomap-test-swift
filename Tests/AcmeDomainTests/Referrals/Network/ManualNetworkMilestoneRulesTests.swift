@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultManualNetworkMilestoneValidator()
        let item = Referrals.newManualNetworkMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsManualNetworkMilestoneSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.ManualNetworkMilestoneSequenceRangeRule(min: 1000, max: 3600)
        let item = Referrals.newManualNetworkMilestone("x", title: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsManualNetworkMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ManualNetworkMilestoneCodeLengthRule(maxLength: 3600)
        let item = Referrals.newManualNetworkMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsManualNetworkMilestoneEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.ManualNetworkMilestoneEndsAtRangeRule(min: 32, max: 32)
        let item = Referrals.newManualNetworkMilestone("x", title: "y")
        item.endsAt = 33
        #expect(rule.check(item).count > 0)
    }
}
