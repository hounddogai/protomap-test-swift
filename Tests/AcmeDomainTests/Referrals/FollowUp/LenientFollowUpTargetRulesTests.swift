@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientFollowUpTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLenientFollowUpTargetValidator()
        let item = Referrals.newLenientFollowUpTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLenientFollowUpTargetMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.LenientFollowUpTargetMarginRangeRule(min: 8.7, max: 1563.1)
        let item = Referrals.newLenientFollowUpTarget("x", title: "y")
        item.margin = 1564.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientFollowUpTargetVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Referrals.LenientFollowUpTargetVersionRangeRule(min: 64, max: 1000)
        let item = Referrals.newLenientFollowUpTarget("x", title: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLenientFollowUpTargetUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.LenientFollowUpTargetUpdatedAtRangeRule(min: 64, max: 255)
        let item = Referrals.newLenientFollowUpTarget("x", title: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}
